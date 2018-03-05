import cpu;
import ppu;
import apu;
import cpuMemory;

enum TvSystem {
	NTSC,
	PAL
}

class Nes {
	
	private Cpu _cpu;
	private Ppu _ppu;
	private Apu _apu;
	
	this() {
		_cpu = new Cpu();
		_ppu = new Ppu();
		_apu = new Apu();
	}
	
	public void reset() {
		
	}
	
	private void masterCycle() {
		
	}
	
	public @property cpu() {return _cpu;}
	public @property ppu() {return _ppu;}
	public @property apu() {return _apu;}
}
