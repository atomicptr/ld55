#include <emscripten/emscripten.h>

extern void game_init();
extern void game_update();

int main() {
    game_init();

    emscripten_set_main_loop(game_update, 0, 1);
    return 0;
}
