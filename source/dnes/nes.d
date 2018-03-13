module dnes.nes;

import dnes;
import std.stdio;
import derelict.sdl2.sdl;

enum TvSystem {
	NTSC,
	PAL
}

class Nes {
	
	private Cpu _cpu;
	private Ppu _ppu;
	private Apu _apu;
	private Rom _rom;
	private Mapper _mapper;
	
	private bool uiActive;
	private SDL_Window* patternTableWindow;
	private SDL_Surface* patterTablesurface;
	private SDL_Renderer* patternTableRenderer;
	
	this() {
		_cpu = new Cpu(this);
		_ppu = new Ppu(this);
		_apu = new Apu(this);
	}
	
	public void startUI() {
		uiActive = true;
		initSdl();
	}
	
	public void loadRom(Rom rom) {
		_rom = rom;
		_mapper = Mapper.createMapper(this, rom);
		writeln("rom loaded! mapperNumber: ", _rom.getMapperNumber());
	}
	
	public void powerUp() {
		_cpu.powerUp();
		_ppu.powerUp();
		_apu.powerUp();
	}
	
	public void reset() {
		_cpu.reset();
		_ppu.reset();
		_apu.reset();
	}
	
	public void run() {
		for(int i = 0; i < 3000000; i++) {
			step();
		}
		endUI();
	}
	
	public void step() {
		cpu.step();
		for(int i = 0; i < 3; i++) {
			ppu.step();
			if(ppu.isVBlankStart()) {
				updateUI();
			}
		}
	}
	
	public @property Cpu cpu() {return _cpu;}
	public @property Ppu ppu() {return _ppu;}
	public @property Apu apu() {return _apu;}
	public @property Rom rom() {return _rom;}
	public @property Mapper mapper() {return _mapper;}
	public @property CpuMemory cpuMemory() {return _cpu.getMemory();}
	
	private void initSdl() {
		if(SDL_Init(SDL_INIT_VIDEO) != 0) assert(false, "sdl init fail!");
		patternTableWindow = SDL_CreateWindow("Pattern Table Debug", 500, 500, 128, 256, SDL_WINDOW_SHOWN);
		if(patternTableWindow == null) {
			writeln("sdl window fail!");
			SDL_Quit();
		}
		patterTablesurface = SDL_GetWindowSurface(patternTableWindow);
		patternTableRenderer = SDL_CreateRenderer(patternTableWindow, -1, SDL_RENDERER_ACCELERATED); 
	}
	
	private void updateUI() {
		if(!uiActive) return;
		renderDebugPatternTable(patternTableRenderer, ppu);
		SDL_Delay(15);
	}
	
	private void endUI() {
		if(!uiActive) return;
		SDL_DestroyWindow(patternTableWindow);
		SDL_Quit();
	}
	
	private void renderDebugPatternTable(SDL_Renderer* renderer, Ppu ppu) {
		for(int i = 0; i < 512; i++) {
			int startX = (i % 16) * 8;
			int startY = (i / 16) * 8;
			ubyte[] pattern = ppu.getPattern(i);
			for(int x = 0; x < 8; x++) {
				for(int y = 0; y < 8; y++) {
					ubyte value = (pattern[y] & (0u << (8u - x))) >> (8u - (x - 1));
					value |= (pattern[y+8] & (0u << (8u - x))) >> (8u - x);
					value *= 85;
					SDL_SetRenderDrawColor(renderer, value, value, value, 255);
					SDL_RenderDrawPoint(renderer, startX + x, startY + y);
				}
			}
		}
		
	}
}


