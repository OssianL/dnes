module dnes.cpumemory;

import dnes.nes;
import std.stdio;
import std.conv;

class CpuMemory {
	private ubyte[65536] memory;
	private Nes nes;
	private bool pageCrossed = false;
	
	this(Nes nes) {
		this.nes = nes;
	}
	
	public ubyte read(Mode accessMode, ubyte immediate, ushort address) {
		if(accessMode == Mode.IMM) {
			return immediate;
		}
		else if(accessMode == Mode.ACC) {
			return nes.cpu.getA();
		}
		else if(accessMode == Mode.ZPG) {
			return zpgRead(immediate);
		}
		else if(accessMode == Mode.ZPX) {
			return zpxRead(immediate);
		}
		else if(accessMode == Mode.ZPY) {
			return zpyRead(immediate);
		}
		else if(accessMode == Mode.ABS) {
			return absRead(address);
		}
		else if(accessMode == Mode.ABX) {
			return abxRead(address);
		}
		else if(accessMode == Mode.ABY) {
			return abyRead(address);
		}
		else if(accessMode == Mode.IND) {
			assert(false, "cpuMemory: no indirect read implemented");
		}
		else if(accessMode == Mode.INX) {
			return inxRead(immediate);
		}
		else if(accessMode == Mode.INY) {
			return inyRead(immediate);
		}
		else {
			assert(false, "memory read mode: " ~ to!string(accessMode) ~ " not implemented");
		}
	}
	
	public ubyte read(ushort address) {
		//io registers
		if(address >= 0x2000 && address < 0x4020) {
			if(address < 0x4000) address = ((address - 0x2000) % 8) + 0x2000; //mirrors $2008-$4000
			//ppu
			if(address == 0x2000) assert(false); //ppu control1 write only
			else if(address == 0x2001) assert(false); //ppu control2 write only
			else if(address == 0x2002) return nes.ppu.readStatusRegister(); //ppu status read only
			else if(address == 0x2003) assert(false); //ppu setSprAddress() write only
			else if(address == 0x2004) return nes.ppu.readOamData();
			else if(address == 0x2005) assert(false); //ppu setScroll() write only
			else if(address == 0x2006) assert(false); //ppu setVramAddress() write only
			else if(address == 0x2007) return nes.ppu.readVram();
			else if(address == 0x4014) assert(false); //direct memory access, write only(?)
			else assert(false);
		}
		else if(address >= 0x8000) return nes.mapper.cpuRead(address);
		else return memory[address]; //normal memory read
	}
	
	public ubyte read(int address) {
		return read(cast(ushort) address);
	}
	
	public ushort read16(int address) {
		ushort value = read(address);//least significant byte first (little endian)
		value += (cast(ushort) (read(address + 1)) << 8);
		return value;
	}
	
	public void write(Mode accessMode, ubyte immediate, ushort address, ubyte value) {
		if(accessMode == Mode.ZPG) {
			return zpgWrite(immediate, value);
		}
		else if(accessMode == Mode.ACC) {
			nes.cpu.setA(value);
		}
		else if(accessMode == Mode.ZPX) {
			return zpxWrite(immediate, value);
		}
		else if(accessMode == Mode.ZPY) {
			return zpyWrite(immediate, value);
		}
		else if(accessMode == Mode.ABS) {
			return absWrite(address, value);
		}
		else if(accessMode == Mode.ABX) {
			return abxWrite(address, value);
		}
		else if(accessMode == Mode.ABY) {
			return abyWrite(address, value);
		}
		else if(accessMode == Mode.IND) {
			assert(false, "cpuMemory: no indirect write implemented");
		}
		else if(accessMode == Mode.INX) {
			return inxWrite(immediate, value);
		}
		else if(accessMode == Mode.INY) {
			return inyWrite(immediate, value);
		}
		else {
			assert(false, "memory write mode not implemented, call the police");
		}
	}
	
	public void write(ushort address, ubyte value) {
		//io registers
		if(address >= 0x2000 && address < 0x4020) {
			if(address < 0x4000) address = ((address - 0x2000) % 8) + 0x2000; //mirrors $2008-$4000
			//ppu
			if(address == 0x2000) nes.ppu.writeControlRegister(value);
			else if(address == 0x2001) nes.ppu.writeMaskRegister(value);
			else if(address == 0x2002) assert(false); //ppu status read only
			else if(address == 0x2003) nes.ppu.writeOamAddress(value);
			else if(address == 0x2004) nes.ppu.writeOamData(value);
			else if(address == 0x2005) nes.ppu.writeScroll(value);
			else if(address == 0x2006) nes.ppu.writeVramAddress(value);
			else if(address == 0x2007) nes.ppu.writeVram(value);
			else if(address == 0x4014) directMemoryAccess(value);
			else assert(false);
		}
		if(address >= 0x8000) nes.mapper.cpuWrite(address, value);
		else memory[address] = value; //normal memory write
	}
	
	public void write(int address, int value) {
		write(cast(ushort) address, cast(ubyte) value);
	}
	
	/*
	Zero Page
	An instruction using zero page addressing mode has only an 8 bit address operand. This limits it to
	addressing only the first 256 bytes of memory (e.g. $0000 to $00FF) where the most significant
	byte of the address is always zero. In zero page mode only the least significant byte of the address
	is held in the instruction making it shorter by one byte (important for space saving) and one less
	memory fetch during execution (important for speed).
	*/
	public ubyte zpgRead(ubyte address) {
		return read(address);
	}
	
	public void zpgWrite(ubyte address, ubyte value) {
		write(address, value);
	}
	
	/*
	Zero Page,X
	The address to be accessed by an instruction using indexed zero page addressing is calculated by taking
	the 8 bit zero page address from the instruction and adding the current value of the X register to it.
	For example if the X register contains $0F and the instruction LDA $80,X is executed then the
	accumulator will be loaded from $008F (e.g. $80 + $0F => $8F).
	*/
	public ubyte zpxRead(ubyte address) {
		return read(cast(ubyte) (address + nes.cpu.getX()));
	}
	
	public void zpxWrite(ubyte address, ubyte value) {
		write(cast(ubyte) (address + nes.cpu.getX()), value);
	}
	
	/*
	Zero Page,Y
	The address to be accessed by an instruction using indexed zero page addressing is calculated by
	taking the 8 bit zero page address from the instruction and adding the current value of the Y register
	to it. This mode can only be used with the LDX and STX instructions.
	*/
	public ubyte zpyRead(ubyte address) {
		return read(cast(ubyte) (address + nes.cpu.getY()));
	}
	
	public void zpyWrite(ubyte address, ubyte value) {
		write(cast(ubyte) (address + nes.cpu.getY()), value);
	}
	
	/*
	Absolute
	Instructions using absolute addressing contain a full 16 bit address to identify the target location.
	*/
	public ubyte absRead(ushort address) {
		return memory[address];
	}
	
	public void absWrite(ushort address, ubyte value) {
		memory[address] = value;
	}
	
	/*
	Absolute,X
	The address to be accessed by an instruction using X register indexed absolute addressing is computed
	by taking the 16 bit address from the instruction and added the contents of the X register. For example
	if X contains $92 then an STA $2000,X instruction will store the accumulator at $2092 (e.g. $2000 + $92).
	*/
	public ubyte abxRead(ushort address) {
		ushort newAddress = cast(ushort) (address + nes.cpu.getX());
		if((address & 0xFF0) != (newAddress & 0xFF00)) setPageCrossed(true);
		return read(newAddress);
	}
	
	public void abxWrite(ushort address, ubyte value) {
		write(cast(ushort) (address + nes.cpu.getX()), value);
	}
	
	/*
	Absolute,Y
	The Y register indexed absolute addressing mode is the same as the previous mode only with the contents
	of the Y register added to the 16 bit address from the instruction.
	*/
	public ubyte abyRead(ushort address) {
		ushort newAddress = cast(ushort) (address + nes.cpu.getY());
		if((address & 0xFF0) != (newAddress & 0xFF00)) setPageCrossed(true);
		return read(newAddress);
	}
	
	public void abyWrite(ushort address, ubyte value) {
		write(cast(ushort) (address + nes.cpu.getY()), value);
	}
	
	/*
	Indexed Indirect
	Indexed indirect addressing is normally used in conjunction with a table of address held on zero page.
	The address of the table is taken from the instruction and the X register added to it (with zero page
	wrap around) to give the location of the least significant byte of the target address.
	*/
	public ubyte inxRead(ubyte address) {
		address = cast(ubyte) (address + nes.cpu.getX());
		ushort realAddress = read(address);
		realAddress |= (cast(ushort) read(cast(ubyte) (address + 1))) << 8;
		//if(nes.cpu.instructions == 6352) writefln("inxRead  newAddress: %x realAddress: %x value: %x", address, realAddress, read(realAddress));
		return read(realAddress);
	}
	
	public void inxWrite(ubyte address, ubyte value) {
		address = cast(ubyte) (address + nes.cpu.getX());
		ushort realAddress = read(address);
		realAddress |= (cast(ushort) read(cast(ubyte) (address + 1))) << 8;
		return write(realAddress, value);
	}
	
	/*
	Indirect Indexed
	Indirect indirect addressing is the most common indirection mode used on the 6502. In instruction
	contains the zero page location of the least significant byte of 16 bit address. The Y register is
	dynamically added to this value to generated the actual target address for operation.
	*/
	public ubyte inyRead(ubyte address) {
		ushort addressAddress = read(address);
		addressAddress |= (cast(ushort) read(cast(ubyte) (address + 1))) << 8;
		ushort realAddress = cast(ushort) (addressAddress + nes.cpu.getY());
		if((addressAddress & 0xFF00) != (realAddress & 0xFF00)) setPageCrossed(true);
		return read(realAddress);
	}
	
	public void inyWrite(ubyte address, ubyte value) {
		ushort realAddress = read16(address);
		return write(realAddress + nes.cpu.getY(), value);
	}
	
	public bool getPageCrossed() {
		return pageCrossed;
	}
	
	public int getPageCrossedValue() {
		if(pageCrossed) return 1;
		return 0;
	}
	
	public void clearPageCrossed() {
		this.pageCrossed = false;
	}
	
	private void setPageCrossed(bool pageCrossed) {
		this.pageCrossed = pageCrossed;
	}
	
	//direct memory access
	private void directMemoryAccess(ubyte address) {
		ushort realAddress = address;
		realAddress *= 0x100;
		for(int i = 0; i < 256; i++) {
			ubyte value = read(realAddress + i);
			write(0x2004, value);
		}
		nes.cpu.stall(513 + (nes.cpu.getCycles() % 2));
	}
}
