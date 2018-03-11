module dnes.tests.nestest;

import dnes.nes;
import dnes.cpu;
import dnes.rom;
import main;
import std.stdio;
import std.file;
import std.regex;
import std.conv;
import std.string;


unittest {
	Nes nes = new Nes();
	Cpu cpu = nes.cpu;
	Rom rom = new Rom("testRoms/nestest.nes");
	nes.loadRom(rom);
	nes.powerUp();
	cpu.setP(0x24);
	cpu.setPC(0xc000);
	cpu.setInterruption(Interruption.NONE);
	
	string lastDebugLine;
	for(int i = 0; i < 8991; i++) {
		cpu.loadNextInstruction();
		string newDebugLine = to!string(cpu.getInstructions()) ~ ": \t" ~ to!string(cpu.getCycles());
		newDebugLine ~= "\t" ~ to!string(cpu.getOperation()) ~ "\t" ~ to!string(cpu.getMode()) ~ "\t" ~ to!string(cpu.getInterruption());
		newDebugLine ~= format!" \t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x"(cpu.getOpcode(), cpu.getImmediate(), cpu.getAddress(), cpu.getPC(), cpu.getSP(), cpu.getA(), cpu.getX(), cpu.getY(), cpu.getP());
		if(!validateNesTestLog(cpu.getInstructions() - 1, cpu.getPC(), cpu.getOperation(), cpu.getA(), cpu.getX(), cpu.getY(), cpu.getP(), cpu.getSP())) {
			writeln("\n\tcycles\top\tmode\tint\topcode\timm\taddr\tpc\tsp\ta\tx\ty\tp");
			writeln(lastDebugLine);
			write("\033[1;31m");
			writeln(newDebugLine);
			write("\033[0m");
			writefln("expected:\t%s\t\t\t\t\t\t%x\t%x\t%x\t%x\t%x\t%x", nesTestOp, nesTestPC, nesTestSP, nesTestA, nesTestX, nesTestY, nesTestP);
			assert(false, "nestest failed");
		}
		lastDebugLine = newDebugLine;
		cpu.step();
	}
}

string[] nesTestLog;
string nesTestOp;
ubyte nesTestA;
ubyte nesTestX;
ubyte nesTestY;
ubyte nesTestP;
ubyte nesTestSP;
ushort nesTestPC;
bool validateNesTestLog(int instructionNumber, ushort pc, Op operation, ubyte a, ubyte x, ubyte y, ubyte p, ubyte sp) {
	if(nesTestLog.length == 0) nesTestLog = readText("testRoms/nestest.log").split("\n");
	string line = nesTestLog[instructionNumber];
	nesTestOp = matchFirst(line, r"(\s|\*)\S\S\S(\s)").hit[1..4];
	nesTestA = matchFirst(line, r"A:\S\S").hit[2..4].to!ubyte(16);
	nesTestX = matchFirst(line, r"X:\S\S").hit[2..4].to!ubyte(16);
	nesTestY = matchFirst(line, r"Y:\S\S").hit[2..4].to!ubyte(16);
	nesTestP = matchFirst(line, r"P:\S\S").hit[2..4].to!ubyte(16);
	nesTestSP = matchFirst(line, r"SP:\S\S").hit[3..5].to!ubyte(16);
	nesTestPC = line[0..4].to!ushort(16);
	if(nesTestOp == "ISB") nesTestOp = "ISC";
	if(pc != nesTestPC) return false;
	if(to!string(operation) != nesTestOp) return false;
	if(a != nesTestA) return false;
	if(x != nesTestX) return false;
	if(y != nesTestY) return false;
	if(p != nesTestP) return false;
	if(sp != nesTestSP) return false;
	return true;
}

