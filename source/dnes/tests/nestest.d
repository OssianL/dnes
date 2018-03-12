module dnes.tests.nestest;

import dnes;
import dnes.tests.logtester;

unittest {
	Nes nes = new Nes();
	Cpu cpu = nes.cpu;
	Rom rom = new Rom("testRoms/nestest.nes");
	nes.loadRom(rom);
	nes.powerUp();
	cpu.setP(0x24);
	cpu.setPC(0xc000);
	cpu.setInterruption(Interruption.NONE);
	assert(LogTester.test("testRoms/nestest.log", nes), "nestest failed");
}

