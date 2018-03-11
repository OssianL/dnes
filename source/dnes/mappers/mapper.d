module dnes.mappers.mapper;

import dnes.nes;
import dnes.rom;
import dnes.mappers.mapper0;


interface Mapper {
	public ubyte cpuRead(ushort address);
	public void cpuWrite(ushort address, ubyte value);
	public ubyte chrRead(ushort address);
	public void chrWrite(ushort address, ubyte value);
	public bool useChrRom(ushort address); //return true if should use chrRom for given address
	
	public static Mapper createMapper(Nes nes, Rom rom) {
		ubyte mapperNumber = rom.getMapperNumber();
		if(mapperNumber == 0) return new Mapper0(nes, rom);
		else assert(false, "unimplemented mapper");
	}
}
