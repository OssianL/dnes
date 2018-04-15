
import dnes;
import std.stdio;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

void main() {
    loadDerelict();
    //benchmark();
    runRom("gitignore/donkeykong.nes");

}

void loadDerelict() {
    DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2ttf.load();
}

void runRom(string romPath) {
    Nes nes = new Nes();
    Rom rom = new Rom(romPath);
    nes.setDebugUIActive(false);
    nes.setLimitFrameRate(true);
    nes.startUI();
    nes.loadRom(rom);
    nes.powerUp();
    nes.run();
}

void benchmark() {
    Nes nes = new Nes();
    nes.startUI();
    nes.setDebugUIActive(false);
    Rom rom = new Rom("gitignore/donkeykong.nes");
    nes.loadRom(rom);
    nes.powerUp();
    nes.setLimitFrameRate(false);
    uint startTicks = SDL_GetTicks();
    for(int i = 0; i < 10000000; i++) {
        nes.step();
    }
    uint endTicks = SDL_GetTicks();
    writeln("Benchmark runtime: ", endTicks - startTicks, "ms");
}