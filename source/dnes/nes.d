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
    private bool screenUIActive = true;
    private bool debugUIActive;
    private bool limitFrameRate;
    private bool quit;
    private SDL_Window* screenWindow;
    private SDL_Renderer* screenRenderer;
    private SDL_Texture* screenTexture;
    private SDL_Window* patternTableWindow;
    private SDL_Renderer* patternTableRenderer;
    private SDL_Window* nameTableWindow;
    private SDL_Renderer* nameTableRenderer;
    private SDL_Window* paletteWindow;
    private SDL_Renderer* paletteRenderer;
    
    this() {
        _cpu = new Cpu(this);
        _ppu = new Ppu(this);
        _apu = new Apu(this);
        _controller1 = new Controller();
        _controller2 = new Controller();
    }
    
    public void startUI() {
        uiActive = true;
        if(SDL_Init(SDL_INIT_VIDEO) != 0) assert(false, "sdl init fail!");
        if(screenUIActive) initScreenUI();
        if(debugUIActive) initDebugUI();
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
        while(!quit) {
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
                handleEvents();
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

    public void setLimitFrameRate(bool limitFrameRate) {
        this.limitFrameRate = limitFrameRate;
    }

    public bool getLimitFrameRate() {
        return limitFrameRate;
    }

    public void setDebugUIActive(bool debugUIActive) {
        this.debugUIActive = debugUIActive;
    }

    public bool getDebugUIActive() {
        return debugUIActive;
    }

    private void initScreenUI() {
        screenWindow = SDL_CreateWindow("primary display", 1000, 250, ppu.screenWidth, ppu.screenHeight, 0);
        if(screenWindow == null) {
            writeln("screenWindow fail!");
            SDL_Quit();
        }
        screenRenderer = SDL_CreateRenderer(screenWindow, -1, SDL_RENDERER_ACCELERATED);
        screenTexture = SDL_CreateTexture(screenRenderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, ppu.screenWidth, ppu.screenHeight);
    }

    private void initDebugUI() {
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
        paletteWindow = SDL_CreateWindow("Palette Debug", 700, 800, 4*16, 8*16, 0);
        if(paletteWindow == null) {
            writeln("paletteWindow fail!");
            SDL_Quit();
        }
        paletteRenderer = SDL_CreateRenderer(paletteWindow, -1, SDL_RENDERER_ACCELERATED);
    }
    
    private void updateUI() {
        if(!uiActive) return;
        if(screenUIActive) renderScreen();
        if(!debugUIActive) return;
        renderDebugPatternTable();
        renderDebugNameTable();
        renderDebugPalette();
        if(limitFrameRate) SDL_Delay(5); //TODO: calculate correct sleep time
    }

    private void handleEvents() {
        if(!uiActive) return;
        SDL_Event e;
        while(SDL_PollEvent(&e) != 0) {
            if(e.type == SDL_QUIT) quit = true;
            else if(e.type == SDL_KEYDOWN) {
                if(e.key.keysym.sym == SDLK_ESCAPE) quit = true;
                switch(e.key.keysym.sym) {
                    case SDLK_UP: return controller1.buttonDown(Controller.Button.up);
                    case SDLK_DOWN: return controller1.buttonDown(Controller.Button.down);
                    case SDLK_RIGHT: return controller1.buttonDown(Controller.Button.right);
                    case SDLK_LEFT: return controller1.buttonDown(Controller.Button.left);
                    case SDLK_z: return controller1.buttonDown(Controller.Button.a);
                    case SDLK_x: return controller1.buttonDown(Controller.Button.b);
                    case SDLK_a: return controller1.buttonDown(Controller.Button.select);
                    case SDLK_s: return controller1.buttonDown(Controller.Button.start);
                    default: return;
                }
            }
            else if(e.type == SDL_KEYUP) {
                switch(e.key.keysym.sym) {
                    case SDLK_UP: return controller1.buttonUp(Controller.Button.up);
                    case SDLK_DOWN: return controller1.buttonUp(Controller.Button.down);
                    case SDLK_RIGHT: return controller1.buttonUp(Controller.Button.right);
                    case SDLK_LEFT: return controller1.buttonUp(Controller.Button.left);
                    case SDLK_z: return controller1.buttonUp(Controller.Button.a);
                    case SDLK_x: return controller1.buttonUp(Controller.Button.b);
                    case SDLK_a: return controller1.buttonUp(Controller.Button.select);
                    case SDLK_s: return controller1.buttonUp(Controller.Button.start);
                    default: return;
                }
            }
        }
    }
    
    private void endUI() {
        if(!uiActive) return;
        if(screenUIActive) SDL_DestroyWindow(screenWindow);
        if(debugUIActive) {
            SDL_DestroyWindow(patternTableWindow);
            SDL_DestroyWindow(nameTableWindow);
            SDL_DestroyWindow(paletteWindow);
        }
        SDL_Quit();
    }

    private void renderScreen() {
        ubyte[] frameBuffer = ppu.getFrameBuffer();
        SDL_UpdateTexture(screenTexture, null, frameBuffer.ptr, ppu.screenWidth * 3);
        SDL_RenderCopy(screenRenderer, screenTexture, null, null);
        SDL_RenderPresent(screenRenderer);
    }
    
    private void renderDebugPatternTable() {
        SDL_SetRenderDrawColor(patternTableRenderer, 0, 0, 0, 255);
        SDL_RenderClear(patternTableRenderer);
        for(int i = 0; i < 512; i++) {
            int x = (i % 16) * 8;
            int y = (i / 16) * 8;
            renderPattern(patternTableRenderer, x, y, i, 0);
        }
        SDL_RenderPresent(patternTableRenderer);
    }
    
    private void renderDebugNameTable() {
        SDL_SetRenderDrawColor(nameTableRenderer, 0, 0, 0, 255);
        SDL_RenderClear(nameTableRenderer);
        for(int nt = 0; nt < 4; nt++) {
            for(int tile = 0; tile < ppu.tilesPerTable; tile++) {
                int y = (tile / 32) * 8;
                int x = (((tile % 32) * 8) + (nt * 32 * 8));
                int tileIndex = tile + (nt * ppu.tilesPerTable);
                int patternIndex = ppu.getTilePatternIndex(tileIndex);
                ubyte attributeValue = ppu.getTileAttributeValue(tileIndex);
                renderPattern(nameTableRenderer, x, y, patternIndex, attributeValue);
            }
        }
        SDL_RenderPresent(nameTableRenderer);
    }
    
    private void renderDebugPalette() {
        SDL_SetRenderDrawColor(paletteRenderer, 0, 0, 0, 255);
        SDL_RenderClear(paletteRenderer);
        SDL_Rect rect;
        rect.w = 16;
        rect.h = 16;
        for(int i = 0; i < 32; i++) {
            rect.x = (i % 4) * 16;
            rect.y = (i / 4) * 16;
            uint color = ppu.getColor(i);
            ubyte r = cast(ubyte) (color >> 16);
            ubyte g = cast(ubyte) (color >> 8);
            ubyte b = cast(ubyte) color;
            SDL_SetRenderDrawColor(paletteRenderer, r, g, b, 255);
            SDL_RenderFillRect(paletteRenderer, &rect);
        }
        SDL_RenderPresent(paletteRenderer);
    }

    private void renderPattern(SDL_Renderer* renderer, int pointX, int pointY, int patternIndex, ubyte attributeValue) {
        int patternStart = patternIndex*16;
        for(int y = 0; y < 8; y++) {
            ushort byte1Address = cast(ushort) (patternStart+y);
            ushort byte2Address = cast(ushort) (byte1Address+8);
            ubyte byte1 = ppu.readVram(byte1Address);
            ubyte byte2 = ppu.readVram(byte2Address);
            for(int x = 7; x >= 0; x--) {
                ubyte pixelValue = byte1 & 1; //bit 0
                byte1 >>= 1;
                pixelValue |= (byte2 & 1) << 1; //bit 1
                byte2 >>= 1;
                uint color = ppu.getColor(pixelValue, attributeValue, false);
                ubyte r = cast(ubyte) (color >> 16);
                ubyte g = cast(ubyte) (color >> 8);
                ubyte b = cast(ubyte) color;
                SDL_SetRenderDrawColor(renderer, r, g, b, 255);
                SDL_RenderDrawPoint(renderer, pointX + x, pointY + y);
            }
        }
    }
}


