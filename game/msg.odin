package game

import "core:container/queue"
import "core:fmt"

Message :: struct {
	type: MessageType,
	data: MessageData,
}

OnMessageFunc :: proc(listener: rawptr, type: MessageType, data: MessageData)

Listener :: struct {
	listener:   rawptr,
	on_message: OnMessageFunc,
}

Broker :: struct {
	listeners: map[MessageType][dynamic]Listener,
	messages:  queue.Queue(Message),
}

broker_create :: proc() -> ^Broker {
	broker := new(Broker)
	return broker
}

broker_register :: proc(
	using self: ^Broker,
	type: MessageType,
	who: rawptr,
	listener_func: OnMessageFunc,
) {
	l := listeners[type]
	append(&l, Listener{who, listener_func})
	listeners[type] = l
}

broker_unregister :: proc(using self: ^Broker, who: rawptr) {
	for message_type in listeners {
		items_to_remove: [dynamic]int

		for listener, index in listeners[message_type] {
			if listener.listener == who {
				append(&items_to_remove, int(index))
			}
		}

		for index in items_to_remove {
			unordered_remove(&listeners[message_type], index)
		}

		delete(items_to_remove)
	}
}

broker_process_messages :: proc(using self: ^Broker) {
	for queue.len(messages) > 0 {
		message := queue.pop_front(&messages)

		message_listeners, ok := listeners[message.type]
		if !ok {
			continue
		}

		for l in message_listeners {
			l.on_message(l.listener, message.type, message.data)
		}
	}
}

broker_post :: proc(using self: ^Broker, type: MessageType, data: MessageData) {
	queue.push_back(&messages, Message{type, data})
}

broker_destroy :: proc(using self: ^Broker) {
	for message_type in listeners {
		delete(listeners[message_type])
	}
	delete(listeners)
	free(self)
}

// the global broker
b: ^Broker
