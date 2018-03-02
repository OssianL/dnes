
enum MirroringType {
	HORIZONTAL,
	VERTICAL,
	FOUR_SCREEN
}

const int[64] colorPalette = [
	0x7C7C7C, 0x0000FC, 0x0000BC, 0x4428BC, 0x940084, 0xA80020, 0xA81000, 0x881400, 0x503000, 0x007800,
	0x006800, 0x005800, 0x004058, 0x000000, 0x000000, 0x000000, 0xBCBCBC, 0x0078F8, 0x0058F8, 0x6844FC,
	0xD800CC, 0xE40058, 0xF83800, 0xE45C10, 0xAC7C00, 0x00B800, 0x00A800, 0x00A844, 0x008888, 0x000000,
	0x000000, 0x000000, 0xF8F8F8, 0x3CBCFC, 0x6888FC, 0x9878F8, 0xF878F8, 0xF85898, 0xF87858, 0xFCA044,
	0xF8B800, 0xB8F818, 0x58D854, 0x58F898, 0x00E8D8, 0x787878, 0x000000, 0x000000, 0xFCFCFC, 0xA4E4FC,
	0xB8B8F8, 0xD8B8F8, 0xF8B8F8, 0xF8A4C0, 0xF0D0B0, 0xFCE0A8, 0xF8D878, 0xD8F878, 0xB8F8B8, 0xB8F8D8,
	0x00FCFC, 0xF8D8F8, 0x000000, 0x000000
];

class Ppu {
	
	private static final ushort backgroundColorAddress = 0x3F00;
	private static final ushort backgroundPalette0 = 0x3F01;
	private static final ushort backgroundPalette1 = 0x3F05;
	private static final ushort backgroundPalette2 = 0x3F09;
	private static final ushort backgroundPalette3 = 0x3F0D;
	private static final ushort spritePalette0 = 0x3F11;
	private static final ushort spritePalette1 = 0x3F15;
	private static final ushort spritePalette2 = 0x3F19;
	private static final ushort spritePalette3 = 0x3F1D;
	
	private ubyte[0x3FFF] ppuRam;
	private ubyte[256] spriteRam;
	private ubyte[32] secondarySpriteRam;
	
	
	//controllerRegister1 $2000
	private ubyte baseNametableAddress; //Base nametable address (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
	private bool vramAddressIncrement; //VRAM address increment per CPU read/write of PPUDATA (0: add 1, going across; 1: add 32, going down)
	private bool spritePatternTableAddress; //Sprite pattern table address for 8x8 sprites (0: $0000; 1: $1000; ignored in 8x16 mode)
	private bool backgroundPatternTableAddress; //Background pattern table address (0: $0000; 1: $1000)
	private bool spriteSize; //Sprite size (0: 8x8; 1: 8x16)
	private bool ppuMasterSlave; //PPU master/slave select (0: read backdrop from EXT pins; 1: output color on EXT pins)
	private bool generateNmi; //Generate an NMI at the start of the vertical blanking interval (0: off; 1: on)

	//controllerRegister2 $2001
	private bool grayscale; //Grayscale (0: normal color; 1: produce a monochrome display)
	private bool showBackgroundInLeft; //1: Show background in leftmost 8 pixels of screen; 0: Hide
	private bool showSpritesInLeft; //1: Show sprites in leftmost 8 pixels of screen; 0: Hide
	private bool showBackground; //1: Show background
	private bool showSprites; //1: Show sprites
	private bool intensifyReds; //Intensify reds (and darken other colors)
	private bool intensifyGreens; //Intensify greens (and darken other colors)
	private bool intensifyBlues; //Intensify blues (and darken other colors)

	/*
	statusRegister bits:
	7654 3210
	|||| ||||
	|||+-++++- Least significant bits previously written into a PPU register
	|||        (due to register not being updated for this address)
	||+------- Sprite overflow.
	|+-------- Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps
	|          a nonzero background pixel; cleared at dot 1 of the pre-render
	|          line.  Used for raster timing.
	+--------- Vertical blank has started (0: not in VBLANK; 1: in VBLANK).
	           Set at dot 1 of line 241 (the line *after* the post-render
	           line); cleared after reading $2002 and at dot 1 of the
	           pre-render line.
	*/
	private ubyte statusRegister; //$2002
	private ubyte sprRamAddress; //$2003
	private ubyte scrollX; //$2005 range 0-255
	private ubyte scrollY; //$2005 range 0-239, values of 240 to 255 are treated as -16 through -1 in a way
	private ushort vramAddress; //$2006 VRAM reading and writing shares the same internal address register that rendering uses
	private ushort tempVramAddress;
	private bool writeToggle = false; //false if waiting for first byte, used for both $2005 and $2006
	
	private uint cycles = 0;
	
	this() {
		//TODO: http://wiki.nesdev.com/w/index.php/PPU_power_up_state
	}
	
	public void cycle() {
		
	}
	
	//$2000
	public void setControlRegister1(ubyte controlRegister1) {
		/*
		controlRegiter1 bits:
		76543210
		||||||++- Base nametable address (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
		|||||+--- VRAM address increment per CPU read/write of PPUDATA (0: add 1, going across; 1: add 32, going down)
		||||+---- Sprite pattern table address for 8x8 sprites (0: $0000; 1: $1000; ignored in 8x16 mode)
		|||+----- Background pattern table address (0: $0000; 1: $1000)
		||+------ Sprite size (0: 8x8; 1: 8x16)
		|+------- PPU master/slave select (0: read backdrop from EXT pins; 1: output color on EXT pins)
		+-------- Generate an NMI at the start of the vertical blanking interval (0: off; 1: on)
		*/
		baseNametableAddress 			= controlRegister1 & 0b00000011;
		vramAddressIncrement			= controlRegister1 & 0b00000100 != 0;
		spritePatternTableAddress		= controlRegister1 & 0b00001000 != 0;
		backgroundPatternTableAddress	= controlRegister1 & 0b00010000 != 0;
		spriteSize						= controlRegister1 & 0b00100000 != 0;
		ppuMasterSlave					= controlRegister1 & 0b01000000 != 0;
		generateNmi						= controlRegister1 & 0b10000000 != 0;
	}
	
	//$2001
	public void setControlRegister2(ubyte controlRegister2) {
		/*
		controlRegister2 bits:
		76543210
		|||||||+- Grayscale (0: normal color; 1: produce a monochrome display)
		||||||+-- 1: Show background in leftmost 8 pixels of screen; 0: Hide
		|||||+--- 1: Show sprites in leftmost 8 pixels of screen; 0: Hide
		||||+---- 1: Show background
		|||+----- 1: Show sprites
		||+------ Intensify reds (and darken other colors)
		|+------- Intensify greens (and darken other colors)
		+-------- Intensify blues (and darken other colors)
		*/
		grayscale				= controlRegister2 & 0b00000001 != 0;
		showBackgroundInLeft	= controlRegister2 & 0b00000010 != 0;
		showSpritesInLeft		= controlRegister2 & 0b00000100 != 0;
		showBackground			= controlRegister2 & 0b00001000 != 0;
		showSprites				= controlRegister2 & 0b00010000 != 0;
		intensifyReds			= controlRegister2 & 0b00100000 != 0;
		intensifyGreens			= controlRegister2 & 0b01000000 != 0;
		intensifyBlues			= controlRegister2 & 0b10000000 != 0;
	}
	
	//$2002
	public ubyte readStatusRegister() {
		writeToggle = false;
		return this.statusRegister;
		//TODO: clear bits and stuff http://wiki.nesdev.com/w/index.php/PPU_registers#Status_.28.242002.29_.3C_read
	}
	
	//$2003
	public void setSprAddress(ubyte address) {
		//http://wiki.nesdev.com/w/index.php/PPU_registers#Obscure_details_of_OAMADDR
	}
	
	//$2004
	public void writeSpr(ubyte data) {
		
	}
	
	//$2004
	public ubyte readSpr() {
		assert(false);
		//Reading OAMDATA while the PPU is rendering will expose internal OAM accesses during sprite evaluation and loading.
	}
	
	//$2005 2 writes needed. first x scroll then y scroll
	public void setScroll(ubyte scroll) {
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
	public void setVramAddress(ubyte part) {
		if(!writeToggle) { 
			tempVramAddress = (cast(ushort) part) << 8;
			writeToggle = true;
		}
		else {
			tempVramAddress += part;
			vramAddress = tempVramAddress;
			writeToggle = false;
		}
	}
	
	//$2007
	public ubyte readVram() {
		return readVram(vramAddress);
		//TODO increment address
	}
	
	public ubyte readVram(ushort address) {
		address = wrap(address);
		if(mapper.useChrRom(address)) return mapper.chrRead(address); //use chrRom or don't
		return ppuRam[address];
	}
	
	//$2007
	public void writeVram() {
		//TODO
	}
	
	/*
	public void setNmiEnabled(bool enabled) {
		if(enabled) controlRegister1 |= 0b10000000;
		else controlRegister1 &= 0b10000000;
	}*/
	
	public bool getNmiEnabled() {
		return cast(bool) controlRegister1 & 0b10000000;
	}
	
	public ushort getBackgroundPatternTableAddress() {
		if(controlRegister1 & 0b00010000) return 0x1000;
		else return 0;
	}
	
	//for 8x8 sprites
	public ushort getSpritePatternTableAddress() {
		if(controlRegister1 & 0b00001000) return 0x1000;
		else return 0;
	}
	
	public ubyte getAddressIncrement() {
		if(controlRegister1 & 0b00000100) return 32; //going down
		else return 1; //going across
	}
	
	public ushort getBaseNameTableAddress() {
		ubyte value = cast(ubyte) (controlRegister1 & 0b00000011);
		if(value == 0) return 0x2000;
		else if(value == 1) return 0x2400;
		else if(value == 2) return 0x2800;
		else if(value == 3) return 0x2C00;
		else assert(false);
	}
	
	private ushort wrap(ushort address) {
		return address % 0x3FFF;
	}
	
	//SPRITE RAM STUFF
	
	private ubyte getSpriteX(ubyte spriteIndex) {
		return spriteRam[(spriteIndex * 4) + 3];
	}
	
	private ubyte getSpriteY(ubyte spriteIndex) {
		return spriteRam[(spriteIndex * 4) + 0];
	}
	
	private ubyte getSpriteTileIndex(ubyte spriteIndex) {
		return spriteRam[(spriteIndex * 4) + 1];
	}
	
	private ubyte getSpritePalette(ubyte spriteIndex) {
		return spriteRam[(spriteIndex * 4) + 2] & 0b00000011; //TODO:  +4???
	}
	
	private bool getSpritePriority(ubyte spriteIndex) {
		if(spriteRam[(spriteIndex * 4) + 2] & 0b00100000) return true;
		return false;
	}
	
	private bool getSpriteHorizontalFlip(ubyte spriteIndex) {
		if(spriteRam[(spriteIndex * 4) + 2] & 0b01000000) return true;
		return false;
	}
	
	private bool getSpriteVerticalFlip(ubyte spriteIndex) {
		if(spriteRam[(spriteIndex * 4) + 2] & 0b10000000) return true;
		return false;
	}
	
}
