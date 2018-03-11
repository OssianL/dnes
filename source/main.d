import nes;
import rom;
import cpu;
import std.stdio;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

SDL_Window* patternTableWindow;
SDL_Surface* patterTablesurface;
SDL_Renderer* patternTableRenderer;

void main() {
	/*
	loadDerelict();
	init();
	patternTableRenderer = SDL_CreateRenderer(patternTableWindow, -1, SDL_RENDERER_ACCELERATED); 
	SDL_Delay(5000);
    */
    
	Nes nes = new Nes();
	Rom rom = new Rom("testRoms/nestest.nes");
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

void init() {
	if(SDL_Init(SDL_INIT_VIDEO) != 0) writeln("sdl init fail!");
	patternTableWindow = SDL_CreateWindow("Pattern Table Debug", 500, 500, 128, 256, SDL_WINDOW_SHOWN);
	if(patternTableWindow == null) {
		writeln("sdl window fail!");
		SDL_Quit();
	}
	patterTablesurface = SDL_GetWindowSurface(patternTableWindow);
}



