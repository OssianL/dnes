import std.file;
import ppu;

enum PrgBankSize = 16384;
enum ChrBankSize = 8192;

alias PrgBank = ubyte[PrgBankSize];
alias ChrBank = ubyte[ChrBankSize];

class Rom {
	
	private ubyte[] header;
	private ubyte[] trainer;
	private PrgBank[] prgBanks;
	private ChrBank[] chrBanks;
	private ubyte[] instRom;
	private ubyte[] pRom;
	
	public bool load(string fileName) {
		ubyte[] file = cast(ubyte[]) read(fileName, 10000000);
		header = file[0..16];
		if(!headerIsValid()) return false;
		int counter = 16;
		if(hasTrainer()) {
			trainer = file[counter..counter+512];
			counter += 512;
		}
		int prgRomSize = getPrgBankCount() * PrgBankSize;
		int chrRomSize = getChrBankCount() * ChrBankSize
		assert(counter + prgRomSize + chrRomSize <= file.length);
		prgRom = file[counter..counter+prgRomSize];
		counter += getPrgBankCount() * PrgBankSize;
		chrRom = file[counter..counter+chrRomSize];
		counter += getChrBankCount() * ChrBankSize;
		//PlayChoice INST-ROM and PROM not implemented
		return true;
	}
	
	public int getPrgBankCount() {
		return header[4];
	}	
	
	public int getChrRomBankCount() {
		return header[5];
	}
	
	public @property PrgBank[] prgBanks(return prgBanks;);
	public @property ChrBank[] chrBanks(return chrBanks;);
	
	public MirroringType getMirroringType() {
		ubyte type = header[6] & 0b00001001;
		if(type == 0) return MirroringType.HORIZONTAL;
		else if(type == 1) return MirroringType.VERTICAL;
		else if(type == 0b1001) return MirroringType.FOUR_SCREEN;
		else assert(false);
	}
	
	public bool hasTrainer() {
		if(header[6] & 0b100) return true;
		else return false;
	}
	
	public ubyte getMapperNumber() {
		ubyte mapper = (header[6] & 0xF0) >> 8;
		mapper += header[7] & 0xF0;
		return mapper;
	}
	
	public TvSystem getTvSystem() {
		return TvSystem.NTSC; //TODO
	}
	
	private bool headerIsValid() {
		if(header[0] != 0x4E || header[1] != 0x45 || header[2] != 0x53 || header[3] != 0x1A) return false;
		if(header[5] == 0) return false;
		if(header[11] != 0 || header[12] != 0 || header[13] != 0 || header[14] != 0 || header[15] != 0) return false;
		return true;
	}
	
}

















