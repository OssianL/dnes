import std.stdio;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

SDL_Window* patternTableWindow;
SDL_Surface* patterTablesurface;
SDL_Renderer* renderer;

int main() {
	loadDerelict();
	init();
	renderer = SDL_CreateRenderer(patternTableWindow, -1, SDL_RENDERER_ACCELERATED); 
	SDL_Delay(5000);
	return 0;
}

void loadDerelict() {
	DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2ttf.load();
}

void init() {
	if(SDL_Init(SDL_INIT_VIDEO) != 0) writeln("sdl init fail!!! kauheeta!!!!");
	patternTableWindow = SDL_CreateWindow("Pattern Table Debug", 100, 100, 256, 128, SDL_WINDOW_SHOWN);
	if(patternTableWindow == null) {
		writeln("sdl window fail hirveetä!!!!!");
		SDL_Quit();
	}
	patterTablesurface = SDL_GetWindowSurface(patternTableWindow);
}

