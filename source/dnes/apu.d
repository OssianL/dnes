module dnes.apu;

import dnes;

class Apu {
	
	private Nes nes;
	
	this(Nes nes) {
		this.nes = nes;
	}
	
	public void powerUp() {
		/*
		from cpu power up:
		$4017 = $00 (frame irq enabled)
		$4015 = $00 (all channels disabled)
		$4000-$400F = $00 (not sure about $4010-$4013)
		All 15 bits of noise channel LFSR = $0000[3]. The first time the LFSR is clocked from the all-0s state, it will shift in a 1.
		*/
	}
	
	public void reset() {
		/*
		from cpu reset:
		APU mode in $4017 was unchanged
		APU was silenced ($4015 = 0)
		*/
	}
	
	public void step() {
	
	}
	
	public void writePulse1Register1(ubyte value) {
		
	}
	
	public void writePulse1Register2(ubyte value) {
		
	}
	
	public void writePulse1Register3(ubyte value) {
		
	}
	
	public void writePulse1Register4(ubyte value) {
		
	}
	
	public void writePulse2Register1(ubyte value) {
		
	}
	
	public void writePulse2Register2(ubyte value) {
		
	}
	
	public void writePulse2Register3(ubyte value) {
		
	}
	
	public void writePulse2Register4(ubyte value) {
		
	}
	
	public void writeTriangleRegister1(ubyte value) {
		
	}
	
	public void writeTriangleRegister2(ubyte value) {
		
	}
	
	public void writeTriangleRegister3(ubyte value) {
		
	}
	
	public void writeNoiseRegister1(ubyte value) {
		
	}
	
	public void writeNoiseRegister2(ubyte value) {
		
	}
	
	public void writeNoiseRegister3(ubyte value) {
		
	}
	
	public void writeDmcRegister1(ubyte value) {
		
	}
	
	public void writeDmcRegister2(ubyte value) {
		
	}
	
	public void writeDmcRegister3(ubyte value) {
		
	}
	
	public void writeDmcRegister4(ubyte value) {
		
	}
	
	public void writeStatusRegister(ubyte value) {
	
	}
	
	public ubyte readStatusRegister() {
		return 0;
	}
	
	public void writeFrameCounter(ubyte value) {
	
	}
	
}
