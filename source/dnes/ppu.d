module dnes.ppu;

import dnes;
import std.stdio;

enum MirroringType {
    horizontal,
    vertical,
    fourScreen
}

const uint[64] colorPalette = [
    0x7C7C7C, 0x0000FC, 0x0000BC, 0x4428BC, 0x940084, 0xA80020, 0xA81000, 0x881400, 0x503000, 0x007800,
    0x006800, 0x005800, 0x004058, 0x000000, 0x000000, 0x000000, 0xBCBCBC, 0x0078F8, 0x0058F8, 0x6844FC,
    0xD800CC, 0xE40058, 0xF83800, 0xE45C10, 0xAC7C00, 0x00B800, 0x00A800, 0x00A844, 0x008888, 0x000000,
    0x000000, 0x000000, 0xF8F8F8, 0x3CBCFC, 0x6888FC, 0x9878F8, 0xF878F8, 0xF85898, 0xF87858, 0xFCA044,
    0xF8B800, 0xB8F818, 0x58D854, 0x58F898, 0x00E8D8, 0x787878, 0x000000, 0x000000, 0xFCFCFC, 0xA4E4FC,
    0xB8B8F8, 0xD8B8F8, 0xF8B8F8, 0xF8A4C0, 0xF0D0B0, 0xFCE0A8, 0xF8D878, 0xD8F878, 0xB8F8B8, 0xB8F8D8,
    0x00FCFC, 0xF8D8F8, 0x000000, 0x000000
];

class Ppu {
    
    enum backgroundColorAddress = 0x3F00;
    enum backgroundPalette0 = 0x3F01;
    enum backgroundPalette1 = 0x3F05;
    enum backgroundPalette2 = 0x3F09;
    enum backgroundPalette3 = 0x3F0D;
    enum spritePalette0 = 0x3F11;
    enum spritePalette1 = 0x3F15;
    enum spritePalette2 = 0x3F19;
    enum spritePalette3 = 0x3F1D;
    
    enum cyclesPerScanline = 341;
    enum scanlinesPerFrame = 262;
    enum visibleStartScanline = 0;
    enum postRenderScanline = 240;
    enum vBlankStartScanline = 241;
    enum preRenderScanline = 261;
    
    enum spriteCount = 64;
    enum tileTableWidth = 32;
    enum tileTableHeight = 30;
    enum tilesPerTable = tileTableWidth * tileTableHeight;
    enum nameTableSize = 0x3c0;
    enum screenWidth = 256;
    enum screenHeight = 240; //only 224 are shown on ntsc tv
    
    private ubyte[0x3FFF] ppuRam;
    private ubyte[256] oamRam;
    private ubyte[32] secondarySpriteRam;
    private Nes nes;
    private MirroringType mirroringType;
    
    //controllerRegister $2000
    private ubyte baseNametableAddress; //Base nametable address (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
    private bool vramAddressIncrement; //VRAM address increment per CPU read/write of PPUDATA (0: add 1, going across; 1: add 32, going down)
    private bool spritePatternTableAddress; //Sprite pattern table address for 8x8 sprites (0: $0000; 1: $1000; ignored in 8x16 mode)
    private bool backgroundPatternTableAddress; //Background pattern table address (0: $0000; 1: $1000)
    private bool spriteSize; //Sprite size (0: 8x8; 1: 8x16)
    private bool ppuMasterSlave; //PPU master/slave select (0: read backdrop from EXT pins; 1: output color on EXT pins)
    private bool generateNmi; //Generate an NMI at the start of the vertical blanking interval (0: off; 1: on)

    //maskRegister $2001
    private bool grayscale; //Grayscale (0: normal color; 1: produce a monochrome display)
    private bool showBackgroundInLeft; //1: Show background in leftmost 8 pixels of screen; 0: Hide
    private bool showSpritesInLeft; //1: Show sprites in leftmost 8 pixels of screen; 0: Hide
    private bool showBackground; //1: Show background
    private bool showSprites; //1: Show sprites
    private bool intensifyReds; //Intensify reds (and darken other colors)
    private bool intensifyGreens; //Intensify greens (and darken other colors)
    private bool intensifyBlues; //Intensify blues (and darken other colors)

    //statusRegister $2002
    private ubyte lastWriteToPpuRegister; //Least significant bits previously written into a PPU register (due to register not being updated for this address)
    private bool spriteOverflow; //Sprite overflow.
    private bool sprite0Hit; //Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps a nonzero background pixel; cleared at dot 1 of the pre-render line.  Used for raster timing.
    private bool vBlankStarted; //Vertical blank has started (0: not in VBLANK; 1: in VBLANK). Set at dot 1 of line 241 (the line *after* the post-render line); cleared after reading $2002 and at dot 1 of the pre-render line.

    private ubyte oamAddress; //$2003
    private ubyte scrollX; //$2005 range 0-255
    private ubyte scrollY; //$2005 range 0-239, values of 240 to 255 are treated as -16 through -1 in a way
    private ushort vramAddress; //$2006 VRAM reading and writing shares the same internal address register that rendering uses
    private ushort tempVramAddress; //address latch
    private bool writeToggle; //false if waiting for first byte, used for both $2005 and $2006
    private ubyte vramDataBuffer; //
    
    private uint cycles;
    private int scanline;
    private uint frame;

    private ubyte[] frameBuffer;
    private ubyte[screenHeight] spriteOverflowCounters;
    
    this(Nes nes) {
        this.nes = nes;
        frameBuffer = new ubyte[screenWidth*screenHeight*3];
    }
    
    public void powerUp() {
        mirroringType = nes.rom.getMirroringType();
        writeControlRegister(0);
        writeMaskRegister(0);
        sprite0Hit = false;
        writeOamAddress(0);
        writeToggle = false;
        vramDataBuffer = 0;
        tempVramAddress = 0;
        scrollX = 0;
        scrollY = 0;
        vramAddress = 0;
        //oddFrame no ???
        //TODO: oamRam = pattern ??? what pattern
        cycles = 0;
        scanline = preRenderScanline;
        frame = 0;
    }
    
    public void reset() {
        writeControlRegister(0);
        writeMaskRegister(0);
        writeToggle = false;
        vramDataBuffer = 0;
        tempVramAddress = 0;
        scrollX = 0;
        scrollY = 0;
        //oddFrame no ???
        //TODO: oamRam = pattern ??? what pattern
        cycles = 0;
        scanline = preRenderScanline;
        frame = 0;
    }
    
    public void step() {
        if(scanline == preRenderScanline) {
            preRender();
        }
        else if(scanline >= 0 && scanline < postRenderScanline) {
            render();
        }
        else if(scanline == postRenderScanline) {
            postRender();
        }
        else if(scanline >= vBlankStartScanline && scanline < preRenderScanline) {
            vBlank();
        }
        bool renderingEnabled = showBackground || showSprites;
        cycles++;
        if(cycles >= cyclesPerScanline) {
            cycles = 0;
            scanline++;
            if(scanline > 261) {
                scanline = 0;
                frame++;
            }   
        }
        //TODO: event/odd frames cycle skip
    }
    
    /* $2000
    controlRegiter bits:
    76543210
    ||||||++- baseNametableAddress
    |||||+--- vramAddressIncrement
    ||||+---- spritePatternTableAddress
    |||+----- backgroundPatternTableAddress
    ||+------ spriteSize
    |+------- ppuMasterSlave
    +-------- generateNmi
    */
    public void writeControlRegister(ubyte value) {
        baseNametableAddress            = value & 0b00000011;
        vramAddressIncrement            = (value & 0b00000100) != 0;
        spritePatternTableAddress       = (value & 0b00001000) != 0;
        backgroundPatternTableAddress   = (value & 0b00010000) != 0;
        spriteSize                      = (value & 0b00100000) != 0;
        ppuMasterSlave                  = (value & 0b01000000) != 0;
        generateNmi                     = (value & 0b10000000) != 0;
        lastWriteToPpuRegister = value;
    }
    
    /* $2001
    mask register bits:
    76543210
    |||||||+- grayscale
    ||||||+-- showBackgroundInLeft
    |||||+--- showSpritesInLeft
    ||||+---- showBackground
    |||+----- showSprites
    ||+------ intensifyReds
    |+------- intensifyGreens
    +-------- intensifyBlues
    */
    public void writeMaskRegister(ubyte value) {
        grayscale               = (value & 0b00000001) != 0;
        showBackgroundInLeft    = (value & 0b00000010) != 0;
        showSpritesInLeft       = (value & 0b00000100) != 0;
        showBackground          = (value & 0b00001000) != 0;
        showSprites             = (value & 0b00010000) != 0;
        intensifyReds           = (value & 0b00100000) != 0;
        intensifyGreens         = (value & 0b01000000) != 0;
        intensifyBlues          = (value & 0b10000000) != 0;
        lastWriteToPpuRegister = value;
    }
    
    /* $2002
    statusRegister bits:
    7654 3210
    |||| ||||
    |||+-++++- lastWriteToPpuRegister
    ||+------- spriteOverflow
    |+-------- sprite0Hit
    +--------- vBlankStarted
    */
    public ubyte readStatusRegister() {
        ubyte status = lastWriteToPpuRegister;
        if(spriteOverflow) status |= 0b00100000;
        if(sprite0Hit) status |= 0b01000000;
        if(vBlankStarted) status |= 0b10000000;
        //Reading the status register will clear vBlankStarted mentioned above and also the address latch used by PPUSCROLL and PPUADDR. It does not clear the sprite 0 hit or overflow bit.
        vBlankStarted = false;
        writeToggle = false;
        return status;
        /*
        TODO:
        Once the sprite 0 hit flag is set, it will not be cleared until the end of the next vertical blank. If attempting to use this flag for raster timing, it is important to ensure that the sprite 0 hit check happens outside of vertical blank, otherwise the CPU will "leak" through and the check will fail. The easiest way to do this is to place an earlier check for D6 = 0, which will wait for the pre-render scanline to begin.
        If using sprite 0 hit to make a bottom scroll bar below a vertically scrolling or freely scrolling playfield, be careful to ensure that the tile in the playfield behind sprite 0 is opaque.
        Sprite 0 hit is not detected at x=255, nor is it detected at x=0 through 7 if the background or sprites are hidden in this area.
        See: PPU rendering for more information on the timing of setting and clearing the flags.
        Some Vs. System PPUs return a constant value in D4-D0 that the game checks.
        Caution: Reading PPUSTATUS at the exact start of vertical blank will return 0 in bit 7 but clear the latch anyway, causing the program to miss frames. See NMI for details.
        */
    }
    
    //$2003
    public void writeOamAddress(ubyte address) {
        oamAddress = address;
        //TODO: http://wiki.nesdev.com/w/index.php/PPU_registers#PPUADDR
    }
    
    //$2004
    public void writeOamData(ubyte value) {
        /*Writes to OAMDATA during rendering (on the pre-render line and the visible lines 0-239,
        provided either sprite or background rendering is enabled) do not modify values in OAM,
        but do perform a glitchy increment of OAMADDR, bumping only the high 6 bits
        (i.e., it bumps the [n] value in PPU sprite evaluation - it's plausible that it could bump
        the low bits instead depending on the current status of sprite evaluation).
        This extends to DMA transfers via OAMDMA, since that uses writes to $2004.
        For emulation purposes, it is probably best to completely ignore writes during rendering.
        */
        //TODO: ignore during rendering
        oamRam[oamAddress] = value;
        oamAddress++;
    }
    
    //$2004
    public ubyte readOamData() {
        //reads during vertical or forced blanking return the value from OAM at that address but do not increment.
        //TODO:Reading OAMDATA while the PPU is rendering will expose internal OAM accesses during sprite evaluation and loading.
        return oamRam[oamAddress];
    }
    
    //$2005 2 writes needed. first x scroll then y scroll
    public void writeScroll(ubyte scroll) {
        if(!writeToggle) {
            scrollX = scroll;
            writeToggle = true;
        }
        else {
            scrollY = scroll;
            writeToggle = false;
        }
        //TODO: Changes made to the vertical scroll during rendering will only take effect on the next frame.
        
    }
    
    //$2006
    public void writeVramAddress(ubyte part) {
        if(!writeToggle) { 
            tempVramAddress = (cast(ushort) part) << 8;
            writeToggle = true;
        }
        else {
            tempVramAddress += part;
            tempVramAddress %= 0x4000; //Valid addresses are $0000-$3FFF; higher addresses will be mirrored down.
            vramAddress = tempVramAddress;
            writeToggle = false;
        }
    }
    
    //$2007
    public ubyte readVram() {
        ubyte value;
        if(vramAddress >= 0x3f00 && vramAddress <= 0x3fff) {
            value = readVram(vramAddress);
            vramDataBuffer = readVram(cast(ushort) (vramAddress - 0x2000)); //is this right? unclear specs
        }
        else {
            value = vramDataBuffer;
            vramDataBuffer = readVram(vramAddress);
        }
        if(vramAddressIncrement) vramAddress += 32;
        else vramAddress += 1;
        return value;
    }
    
    public ubyte readVram(ushort address) {
        if(nes.mapper.useChrRom(address)) return nes.mapper.chrRead(address); //use chrRom or don't
        return ppuRam[internalMemoryMirroring(address)];
    }
    
    //$2007
    public void writeVram(ubyte value) {
        writeVram(vramAddress, value);
        if(vramAddressIncrement) vramAddress += 32;
        else vramAddress += 1;
        //TODO???? VRAM reading and writing shares the same internal address register that rendering uses. So after loading data into video memory, the program should reload the scroll position afterwards with PPUSCROLL writes in order to avoid wrong scrolling.
    }
    
    public void writeVram(ushort address, ubyte value) {
        if(nes.mapper.useChrRom(address)) nes.mapper.chrWrite(address, value);//can write to chrRom?
        else ppuRam[internalMemoryMirroring(address)] = value;
    }
    
    public ushort getBackgroundPatternTableAddress() {
        if(backgroundPatternTableAddress) return 0x1000;
        else return 0;
    }
    
    //for 8x8 sprites
    public ushort getSpritePatternTableAddress() {
        if(spritePatternTableAddress) return 0x1000;
        else return 0;
    }
    
    //return the 2 most significant bit for pattern palette indexes
    public ubyte getTileAttributeValue(uint index) {
        ushort attributeTableAddress = getAttributeTableAddress(index / tilesPerTable);
        index %= tilesPerTable;
        int tileX = index % 32;
        int tileY = index / 32;
        int tileGroupX = tileX / 4;
        int tileGroupY = tileY / 4;
        int tileGroupIndex = tileGroupY * 8 + tileGroupX;
        int squareX = (tileX / 2) % 2;
        int squareY = (tileY / 2) % 2;
        int squareIndex = squareY * 2 + squareX; //0-3
        ubyte tileGroup = readVram(cast(ushort) (attributeTableAddress+tileGroupIndex));
        ubyte attributeValue = cast(ubyte) ((tileGroup >> (squareIndex * 2)) << 2);
        return attributeValue & 0b00001100;
    }
    
    public int getTilePatternIndex(uint tileIndex) {
        int nameTableIndex = tileIndex / tilesPerTable;
        tileIndex %= tilesPerTable;
        ushort tileAddress = cast(ushort) (getNameTableAddress(nameTableIndex) + tileIndex);
        int patternIndex = readVram(tileAddress);
        if(backgroundPatternTableAddress) patternIndex += 256;
        return patternIndex;
    }
    
    public ushort getBaseNameTableAddress() {
        return getNameTableAddress(baseNametableAddress);
    }
    
    public ushort getNameTableAddress(uint index) {
        if(index == 0) return 0x2000;
        else if(index == 1) return 0x2400;
        else if(index == 2) return 0x2800;
        else if(index == 3) return 0x2C00;
        else assert(false);
    }
    
    public ushort getAttributeTableAddress(uint index) {
        return cast(ushort) (getNameTableAddress(index) + nameTableSize);
    }
    
    public uint getColor(ubyte pixelValue, ubyte attributeValue, bool sprite) {
        ubyte paletteIndexAddress = pixelValue | attributeValue;
        if(sprite) paletteIndexAddress |= 0b00010000;
        return getColor(paletteIndexAddress);
    }

    public uint getColor(int paletteIndexAddress) {
        int paletteIndex = readVram(cast(ushort) (backgroundColorAddress+paletteIndexAddress));
        return colorPalette[paletteIndex];
    }

    public ubyte[] getFrameBuffer() {
        return frameBuffer;
    }

    public bool isVBlankStart() {
        return scanline == vBlankStartScanline && cycles == 0;
    }
    
    private void preRender() {
        if(cycles == 0) vBlankStarted = false;
        if(cycles == 1) spriteOverflow = false;
    }

    private void render() {
        
    }

    private void postRender() {

    }

    private void vBlank() {
        if(isVBlankStart()) {
            vBlankStarted = true;
            if(generateNmi) nes.cpu.raiseInterruption(Interruption.NMI);
            renderFrame();
        }
        if(scanline == preRenderScanline - 1 && cycles == cyclesPerScanline) { //vblank end
            sprite0Hit = false;
        }
    }

    private void renderFrame() {
        renderBackground();
        renderSprites();
    }

    private void renderBackground() {
        int tileStartX = scrollX / 8; //first visible upper left tile
        int tileStartY = scrollY / 8;
        int tileStartScreenX = -(scrollX % 8); //screen coordinates of first tile
        int tileStartScreenY = -(scrollY % 8);
        for(int y = 0; y < tileTableHeight; y++) {
            int tileYIndex = (tileStartY + y) * tileTableWidth;
            if((tileStartY + y) >= tileTableHeight) tileYIndex += tilesPerTable;
            for(int x = 0; x < tileTableWidth; x++) {
                int tileIndex = tileYIndex + tileStartX + x;
                if(tileStartX + x >= tileTableWidth) tileIndex += tilesPerTable;
                renderTile(tileIndex,  x*8 + tileStartScreenX, y*8 + tileStartScreenY);
            }
        }
    }

    private void renderSprites() {
        for(int i = spriteCount - 1; i >= 0; i--) { //earlier sprites have priority and get drawn on top (after)
            ubyte y = getSpriteY(i);
            if(y == 0) continue;
            ubyte x = getSpriteX(i);
            ubyte patternIndex = getSpritePatternIndex(i);
            ubyte attributeValue = getSpriteAttributeValue(i);
            bool flipVertical = getSpriteVerticalFlip(i);
            bool flipHorizontal = getSpriteHorizontalFlip(i);
            bool priority = getSpritePriority(i);
            renderPattern(patternIndex, attributeValue, x, y, flipHorizontal, flipVertical, true, i == 0, priority);
        }
    }

    private void renderTile(int tileIndex, int screenX, int screenY) {
        int patternIndex = getTilePatternIndex(tileIndex);
        ubyte attributeValue = getTileAttributeValue(tileIndex);
        renderPattern(patternIndex, attributeValue, screenX, screenY, false, false, false, false, false);
    }

    private void renderPattern(int patternIndex, ubyte attributeValue, int posX, int posY, bool flipHorizontal, bool flipVertical, bool isSprite, bool isSpriteZero, bool priority) {
        int patternStart = patternIndex*16;
        uint backgroundColor = getColor(0, 0, false);
        for(int y = 0; y < 8; y++) {
            int patternY = flipVertical ? 7 - y : y;
            int pixelY = posY + patternY;
            if(pixelY >= screenHeight || pixelY < 0) continue;
            if(isSprite) {
                spriteOverflowCounters[pixelY]++;
                if(spriteOverflowCounters[pixelY] > 8) spriteOverflow = true;
            }
            ushort byte1Address = cast(ushort) (patternStart+patternY);
            ushort byte2Address = cast(ushort) (byte1Address+8);
            ubyte byte1 = readVram(byte1Address);
            ubyte byte2 = readVram(byte2Address);
            for(int x = 0; x < 8; x++) {
                int patternX = flipHorizontal ? x : 7 - x;
                int pixelX = posX + patternX;
                if(pixelX >= screenWidth || pixelX < 0) continue;
                ubyte pixelValue = byte1 & 1; //bit 0
                byte1 >>= 1;
                pixelValue |= (byte2 & 1) << 1; //bit 1
                byte2 >>= 1;
                if(isSprite && pixelValue == 0) continue; //don't draw sprite background
                uint pixelIndex = (((pixelY) * screenWidth) + pixelX) * 3;
                uint oldColor = (((frameBuffer[pixelIndex] << 8) | frameBuffer[pixelIndex+1]) << 8) | frameBuffer[pixelIndex+2]; //TODO: optimize, pointer cast thing
                if(isSprite && priority && oldColor != backgroundColor) continue; //only draw on background color
                if(isSpriteZero && oldColor != backgroundColor && pixelValue != 0) sprite0Hit = true;
                uint color = getColor(pixelValue, attributeValue, isSprite);
                frameBuffer[pixelIndex] = cast(ubyte) (color >> 16); //red
                frameBuffer[pixelIndex+1] = cast(ubyte) (color >> 8); //green
                frameBuffer[pixelIndex+2] = cast(ubyte) color; //blue
            }
        }
    }

    private ushort internalMemoryMirroring(ushort address) {
        address %= 0x3FFF; //$4000-$10000 mirrors $0000-$3fff
        if(address >= 0x3000 && address < 0x3f00) address -= 0x1000; //$3000-$3eff mirrors $2000-$2eff
        else if(address >= 0x3f20 && address < 0x4000) address = 0x3f00 + ((address - 0x3f20) % 0x20); //$3f20-$3fff mirrors $3f00-$3f1f
        //palette mirroring
        if(address == 0x3f10) address = 0x3f00;
        else if(address == 0x3f14) address = 0x3f04;
        else if(address == 0x3f18) address = 0x3f08;
        else if(address == 0x3f1c) address = 0x3f0c;
        //name table mirroring
        if(address >= 0x2400 && address < 0x2800 && mirroringType == MirroringType.horizontal)
            address = cast(ushort) (address - 0x400);
        else if(address >= 0x2800 && address < 0x2c00 && mirroringType == MirroringType.vertical)
            address = cast(ushort) (address - 0x800);
        else if(address >= 0x2c00 && address < 0x3000) {
            if(mirroringType == MirroringType.horizontal)
                address = cast(ushort) (address - 0x400);
            else if(mirroringType == MirroringType.vertical)
                address = cast(ushort) (address - 0x800);
        }
        return address;
    }
    
    //SPRITE RAM STUFF
    
    private ubyte getSpriteX(int spriteIndex) {
        return oamRam[(spriteIndex * 4) + 3];
    }
    
    private ubyte getSpriteY(int spriteIndex) {
        return cast(ubyte) (oamRam[(spriteIndex * 4) + 0] + 1);
    }
    
    private ubyte getSpritePatternIndex(int spriteIndex) {
        return oamRam[(spriteIndex * 4) + 1];
    }
    
    private ubyte getSpriteAttributeValue(int spriteIndex) {
        return (oamRam[(spriteIndex * 4) + 2] & 0b00000011) << 2;
    }
    
    private bool getSpritePriority(int spriteIndex) {
        if(oamRam[(spriteIndex * 4) + 2] & 0b00100000) return true;
        return false;
    }
    
    private bool getSpriteHorizontalFlip(int spriteIndex) {
        if(oamRam[(spriteIndex * 4) + 2] & 0b01000000) return true;
        return false;
    }
    
    private bool getSpriteVerticalFlip(int spriteIndex) {
        if(oamRam[(spriteIndex * 4) + 2] & 0b10000000) return true;
        return false;
    }
}
