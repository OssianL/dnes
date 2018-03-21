
import dnes;
import std.stdio;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

void main() {
	loadDerelict();
	Nes nes = new Nes();
	nes.startUI();
	Rom rom = new Rom("gitignore/donkeykong.nes");
	nes.loadRom(rom);
	nes.powerUp();
	nes.run();
}

void loadDerelict() {
	DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2ttf.load();
}

