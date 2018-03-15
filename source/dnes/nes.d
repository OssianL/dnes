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
	private Controller _controller1;
	private Controller _controller2;
	
	private bool uiActive;
	private SDL_Window* patternTableWindow;
	private SDL_Renderer* patternTableRenderer;
	
	this() {
		_cpu = new Cpu(this);
		_ppu = new Ppu(this);
		_apu = new Apu(this);
		_controller1 = new Controller();
		_controller2 = new Controller();
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
		for(int i = 0; i < 50000; i++) {
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
	public @property CpuMemory cpuMemory() {return _cpu.getMemory();}
	public @property Ppu ppu() {return _ppu;}
	public @property Apu apu() {return _apu;}
	public @property Rom rom() {return _rom;}
	public @property Mapper mapper() {return _mapper;}
	public @property Controller controller1() {return _controller1;}
	public @property Controller controller2() {return _controller2;}
	
	private void initSdl() {
		if(SDL_Init(SDL_INIT_VIDEO) != 0) assert(false, "sdl init fail!");
		patternTableWindow = SDL_CreateWindow("Pattern Table Debug", 500, 500, 128, 256, 0);
		if(patternTableWindow == null) {
			writeln("sdl window fail!");
			SDL_Quit();
		}
		patternTableRenderer = SDL_CreateRenderer(patternTableWindow, -1, SDL_RENDERER_ACCELERATED); 
	}
	
	private void updateUI() {
		if(!uiActive) return;
		SDL_SetRenderDrawColor(patternTableRenderer, 255, 100, 0, 255);
		SDL_RenderClear(patternTableRenderer);
		renderDebugPatternTable(patternTableRenderer, ppu);
		SDL_RenderPresent(patternTableRenderer);
		SDL_Delay(5000);
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
			int patternStart = i*16;
			for(int y = 0; y < 8; y++) {
				ushort byte1Address = cast(ushort) (patternStart+y);
				ushort byte2Address = cast(ushort) (byte1Address+8);
				ubyte byte1 = ppu.readVram(byte1Address);
				ubyte byte2 = ppu.readVram(byte2Address);
				for(int x = 8; x >= 0; x--) {
					ubyte value = byte1 & 1; //bit 0
					byte1 >>= 1;
					value |= (byte2 & 1) << 1; //bit 1
					byte2 >>= 1;
					value *= 85;
					SDL_SetRenderDrawColor(renderer, value, value, value, 255);
					SDL_RenderDrawPoint(renderer, startX + x, startY + y);
				}
			}
		}
		
	}
}


