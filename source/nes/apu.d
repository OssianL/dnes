
class Apu {
	
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
}
