module dnes.rom;

import dnes.nes;
import std.file;
import std.stdio;

enum prgBankSize = 16384;
enum chrBankSize = 8192;

alias PrgBank = ubyte[prgBankSize];
alias ChrBank = ubyte[chrBankSize];

enum TvSystem {
	PAL,
	NTSC
}

class Rom {

	private ubyte prgBankCount;
	private ubyte chrBankCount;
	private bool hasTrainer;
	private MirroringType mirroringType;
	private ubyte mapperNumber;
	private ubyte[] trainer;
	private PrgBank[] _prgBanks;
	private ChrBank[] _chrBanks;
	private ubyte[] instRom;
	private ubyte[] pRom;
	
	this(string fileName) {
		if(!load(fileName)) writeln("rom load failed");
	}
	
	public bool load(string fileName) {
		ubyte[] file = cast(ubyte[]) read(fileName, 10000000);
		ubyte[] header = file[0..16];
		if(!headerIsValid(header)) return false;
		prgBankCount = header[4];
		chrBankCount = header[5];
		hasTrainer = cast(bool) (header[6] & 0b100);
		setMirroringType(header[6]);
		setMapperNumber(header[6], header[7]);
		int counter = 16;
		if(hasTrainer) {
			trainer = file[counter..counter+512];
			counter += 512;
		}
		int prgRomSize = prgBankCount * prgBankSize;
		int chrRomSize = chrBankCount * chrBankSize;
		assert(counter + prgRomSize + chrRomSize <= file.length);
		_prgBanks = new PrgBank[prgBankCount];
		for(int i = 0; i < prgBankCount; i++) {
			_prgBanks[i] = new ubyte[prgBankSize];
			int start = counter + (i * prgBankSize);
			_prgBanks[i][] = file[start..start+prgBankSize];
		}
		counter += prgBankCount * prgBankSize;
		_chrBanks = new ChrBank[chrBankCount];
		for(int i = 0; i < chrBankCount; i++) {
			_chrBanks[i] = new ubyte[chrBankSize];
			int start = counter + (i * chrBankSize);
			_chrBanks[i][] = file[start..start+chrBankSize];
		}
		counter += chrBankCount * chrBankSize;
		//PlayChoice INST-ROM and PROM not implemented
		return true;
	}
	
	public @property PrgBank[] prgBanks() {return _prgBanks;}
	public @property ChrBank[] chrBanks() {return _chrBanks;}
	
	
	public TvSystem getTvSystem() {
		return TvSystem.NTSC; //TODO
	}
	
	public ubyte getMapperNumber() {
		return mapperNumber;
	}
	
	private bool headerIsValid(ubyte[] header) {
		if(header[0] != 0x4E || header[1] != 0x45 || header[2] != 0x53 || header[3] != 0x1A) return false;
		if(header[5] == 0) return false;
		if(header[11] != 0 || header[12] != 0 || header[13] != 0 || header[14] != 0 || header[15] != 0) return false;
		return true;
	}
	
	private void setMirroringType(ubyte header6) {
		header6 &= 0b00001001;
		if(header6 == 0) mirroringType = MirroringType.HORIZONTAL;
		else if(header6 == 1) mirroringType = MirroringType.VERTICAL;
		else if(header6 == 0b1001) mirroringType = MirroringType.FOUR_SCREEN;
		else assert(false);
	}
	
	private void setMapperNumber(ubyte header6, ubyte header7) {
		mapperNumber = (header6 & 0xF0) >> 8;
		mapperNumber += header7 & 0xF0;
	}
}

