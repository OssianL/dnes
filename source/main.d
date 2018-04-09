
import dnes;
import std.stdio;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

void main() {
	loadDerelict();
	benchmark();
	/*
	Nes nes = new Nes();
	nes.startUI();
	Rom rom = new Rom("gitignore/donkeykong.nes");
	//Rom rom = new Rom("testRoms/scroll.nes");
	nes.loadRom(rom);
	nes.powerUp();
	nes.run();
	*/
}

void loadDerelict() {
	DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2ttf.load();
}

void benchmark() {
	Nes nes = new Nes();
    nes.startUI();
    Rom rom = new Rom("gitignore/donkeykong.nes");
    nes.loadRom(rom);
    nes.powerUp();
    nes.setDebugUIActive(false);
    nes.setLimitFrameRate(false);
    uint startTicks = SDL_GetTicks();
    for(int i = 0; i < 10000000; i++) {
        nes.step();
    }
    uint endTicks = SDL_GetTicks();
    writeln("Benchmark runtime: ", endTicks - startTicks, "ms");
}