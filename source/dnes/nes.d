module dnes.nes;

import dnes.cpu;
import dnes.ppu;
import dnes.apu;
import dnes.cpumemory;
import dnes.rom;
import dnes.mappers.mapper;
import std.stdio;

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
	
	this() {
		_cpu = new Cpu(this);
		_ppu = new Ppu(this);
		_apu = new Apu(this);
	}
	
	public void loadRom(Rom rom) {
		_rom = rom;
		_mapper = Mapper.createMapper(this, rom);
		writeln("rom loaded! mapperNumber: ", _rom.getMapperNumber());
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
		for(int i = 0; i < 8991; i++) {
			_cpu.step();
			_ppu.step();
			_ppu.step();
			_ppu.step();
		}
	}
	
	public @property Cpu cpu() {return _cpu;}
	public @property Ppu ppu() {return _ppu;}
	public @property Apu apu() {return _apu;}
	public @property Rom rom() {return _rom;}
	public @property Mapper mapper() {return _mapper;}
	public @property CpuMemory cpuMemory() {return _cpu.getMemory();}
}
