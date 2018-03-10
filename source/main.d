import nes;
import rom;
import cpu;
import std.stdio;
import std.file;
import std.regex;
import std.conv;
import std.string;
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


string[] nesTestLog;
bool validateNesTestLog(int instructionNumber, ushort pc, Op operation, ubyte a, ubyte x, ubyte y, ubyte p, ubyte sp) {
	if(nesTestLog.length == 0) nesTestLog = readText("testRoms/nestest.log").split("\n");
	string line = nesTestLog[instructionNumber];
	if(pc != line[0..4].to!ushort(16)) return false;
	string nesTestOp = matchFirst(line, r"(\s|\*)\S\S\S(\s)").hit[1..4];
	if(nesTestOp == "ISB") nesTestOp = "ISC";
	if(to!string(operation) != nesTestOp) return false;
	if(a != matchFirst(line, r"A:\S\S").hit[2..4].to!ubyte(16)) return false;
	if(x != matchFirst(line, r"X:\S\S").hit[2..4].to!ubyte(16)) return false;
	if(y != matchFirst(line, r"Y:\S\S").hit[2..4].to!ubyte(16)) return false;
	if(p != matchFirst(line, r"P:\S\S").hit[2..4].to!ubyte(16)) return false;
	if(sp != matchFirst(line, r"SP:\S\S").hit[3..5].to!ubyte(16)) return false;
	return true;
}
