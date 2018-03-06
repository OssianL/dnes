import cpu;
import ppu;
import apu;
import cpuMemory;
import rom;
import mapper;

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
	private CpuMemory _cpuMemory;
	
	this() {
		_cpuMemory = new CpuMemory(this);
		_cpu = new Cpu(_cpuMemory);
		_ppu = new Ppu(this);
		_apu = new Apu(this);
	}
	
	public void loadRom(Rom rom) {
		_rom = rom;
		_mapper = Mapper.createMapper(this, rom);
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
		
	}
	
	private void masterCycle() {
		
	}
	
	public @property Cpu cpu() {return _cpu;}
	public @property Ppu ppu() {return _ppu;}
	public @property Apu apu() {return _apu;}
	public @property Rom rom() {return _rom;}
	public @property Mapper mapper() {return _mapper;}
	public @property CpuMemory cpuMemory() {return _cpuMemory;}
}
