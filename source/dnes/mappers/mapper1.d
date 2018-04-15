module dnes.mappers.mapper1;

import dnes;
/*
class Mapper1 : Mapper {


    private Nes nes;
    private Rom rom;
    
    public this(Nes nes, Rom rom) {
        this.nes = nes;
        this.rom = rom;
    }
    
    public ubyte cpuRead(ushort address) {
        if(address < 0x8000) assert(false);
        if(address >= 0xc000) return rom.prgBanks[$-1][address - 0xc000];//last bank
        return rom.prgBanks[0][address - 0x8000];
    }
    
    public void cpuWrite(ushort address, ubyte value) {
        //no registers
    }
    
    public ubyte chrRead(ushort address) {
        return rom.chrBanks[0][address];
    }
    
    public void chrWrite(ushort address, ubyte value) {
        assert(false);
    }
    
    public bool useChrRom(ushort address) {
        return rom.chrBanks.length > 0 && address < 0x2000;
    }
}
*/