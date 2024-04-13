package game

Item :: struct($Id: typeid) {
	id:    Id,
	alive: bool,
}

Collection :: struct($Id: typeid, $T: typeid/Item(Id), $N: uint) {
	col_items: #soa[N]T,
	col_index: Id,
	col_count: uint,
}

col_new_id :: proc(using self: ^Collection($Id, $T, $N)) -> (Id, bool) {
	reused_index := false
	tmp_index := col_index

	for i in 0 ..< col_index {
		if !col_items[i].alive {
			reused_index = true
			tmp_index = i
			break
		}
	}

	// we reached the max, dont do anything
	if tmp_index == col_index && col_index >= Id(N) {
		return Id(0), false
	}

	col_count += 1

	if reused_index {
		return tmp_index, true
	}

	col_index += 1
	return tmp_index, true
}

col_free_id :: proc(using self: ^Collection($Id, $T, $N), id: Id) {
	col_items[id].alive = false
	col_count -= 1
}
