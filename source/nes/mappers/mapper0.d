import mapper;
import nes;
import rom;

/**
https://wiki.nesdev.com/w/index.php/INES_Mapper_000
The generic designation NROM refers to the Nintendo cartridge boards
NES-NROM-128, NES-NROM-256, their HVC counterparts, and clone boards.
The iNES format assigns mapper 0 to NROM.

Overview
PRG ROM size: 16 KiB for NROM-128, 32 KiB for NROM-256 (DIP-28 standard pinout)
PRG ROM bank size: Not bankswitched
PRG RAM: 2 or 4 KiB, not bankswitched, only in Family Basic (but most emulators provide 8)
CHR capacity: 8 KiB ROM (DIP-28 standard pinout) but most emulators support RAM
CHR bank size: Not bankswitched, see CNROM
Nametable mirroring: Solder pads select vertical or horizontal mirroring
Subject to bus conflicts: Yes, but irrelevant

Banks
All Banks are fixed,
CPU $6000-$7FFF: Family Basic only: PRG RAM, mirrored as necessary to
fill entire 8 KiB window, write protectable with an external switch
CPU $8000-$BFFF: First 16 KB of ROM.
CPU $C000-$FFFF: Last 16 KB of ROM (NROM-256) or mirror of $8000-$BFFF (NROM-128).

Solder pad config
Horizontal mirroring : 'H' disconnected, 'V' connected.
Vertical mirroring : 'H' connected, 'V' disconnected.

Registers
None. This has normally no mapping capability whatsoever! Nevertheless,
tile animation can be done by swapping between pattern tables $0000 and $1000,
using PPUCTRL bits 4-3 as a "poor man's CNROM".
**/
class Mapper0 : Mapper {
	
	private Nes nes;
	private Rom rom;
	
	public this(Nes nes, Rom rom) {
		this.nes = nes;
		this.rom = rom;
	}
	
	public ubyte cpuRead(ushort address) {
		if(address < 0x8000) assert(false);
		if(address >= 0xc000) return rom.prgBanks[$][address - 0xc0000];//last bank or first
		return rom.prgBanks[0][address - 0x8000];
	}
	
	public void cpuWrite(ushort address, ubyte value) {
		//no registers
	}
	
	public ubyte chrRead(ushort address) {
		assert(false);
	}
	
	public void chrWrite(ushort address, ubyte value) {
		assert(false);
	}
	
	public bool useChrRom(ushort address) {
		return false;
	}
	
}
