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
	private SDL_Window* nameTableWindow;
	private SDL_Renderer* nameTableRenderer;
	
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
		writeln("rom loaded! mapperNumber: ", _rom.getMapperNumber(), " mirroring: ", rom.getMirroringType());
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
		for(int i = 0; i < 4000000; i++) {
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
			writeln("patternTableWindow fail!");
			SDL_Quit();
		}
		patternTableRenderer = SDL_CreateRenderer(patternTableWindow, -1, SDL_RENDERER_ACCELERATED);
		nameTableWindow = SDL_CreateWindow("Name Table Debug", 700, 500, 1024, 240, 0);
		if(patternTableWindow == null) {
			writeln("nameTableWindow fail!");
			SDL_Quit();
		}
		nameTableRenderer = SDL_CreateRenderer(nameTableWindow, -1, SDL_RENDERER_ACCELERATED);
	}
	
	private void updateUI() {
		if(!uiActive) return;
		SDL_SetRenderDrawColor(patternTableRenderer, 0, 0, 0, 255);
		SDL_RenderClear(patternTableRenderer);
		SDL_SetRenderDrawColor(nameTableRenderer, 0, 0, 0, 255);
		SDL_RenderClear(nameTableRenderer);
		renderDebugPatternTable();
		renderDebugNameTable();
		SDL_RenderPresent(patternTableRenderer);
		SDL_RenderPresent(nameTableRenderer);
		//SDL_Delay();
	}
	
	private void endUI() {
		if(!uiActive) return;
		SDL_DestroyWindow(patternTableWindow);
		SDL_Quit();
	}
	
	private void renderDebugPatternTable() {
		for(int i = 0; i < 512; i++) {
			int x = (i % 16) * 8;
			int y = (i / 16) * 8;
			renderPattern(patternTableRenderer, x, y, i, 0);
		}
	}
	
	private void renderDebugNameTable() {
		for(int nt = 0; nt < 4; nt++) {
			for(int tile = 0; tile < ppu.tilesPerTable; tile++) {
				int y = (tile / 32) * 8;
				int x = (((tile % 32) * 8) + (nt * 32 * 8));
				int tileIndex = tile + (nt * ppu.tilesPerTable);
				int patternIndex = ppu.getTilePatternIndex(tileIndex);
				ubyte attributeValue = ppu.getTileAttributeValue(tileIndex);
				//writefln("attributeValue: %x", attributeValue);
				renderPattern(nameTableRenderer, x, y, patternIndex, attributeValue);
			}
		}
	}
	
	private void renderPattern(SDL_Renderer* renderer, int pointX, int pointY, int patternIndex, ubyte attributeValue) {
		int patternStart = patternIndex*16;
		for(int y = 0; y < 8; y++) {
			ushort byte1Address = cast(ushort) (patternStart+y);
			ushort byte2Address = cast(ushort) (byte1Address+8);
			ubyte byte1 = ppu.readVram(byte1Address);
			ubyte byte2 = ppu.readVram(byte2Address);
			for(int x = 8; x >= 0; x--) {
				ubyte pixelValue = byte1 & 1; //bit 0
				byte1 >>= 1;
				pixelValue |= (byte2 & 1) << 1; //bit 1
				byte2 >>= 1;
				//writefln("pixerlValue: %x attributeValue: %x", pixelValue, attributeValue);
				uint color = ppu.getColor(pixelValue, attributeValue, false);
				ubyte r = cast(ubyte) (color >> 16);
				ubyte g = cast(ubyte) (color >> 8);
				ubyte b = cast(ubyte) color;
				//writefln("x: %s y: %s color: %x r: %x g: %x b: %x", pointX, pointY, color, r, g, b);
				SDL_SetRenderDrawColor(renderer, r, g, b, 255);
				SDL_RenderDrawPoint(renderer, pointX + x, pointY + y);
			}
		}
	}
	
}


