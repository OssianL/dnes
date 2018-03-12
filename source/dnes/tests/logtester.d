module dnes.tests.logtester;

import dnes;
import std.stdio;
import std.file;
import std.regex;
import std.conv;
import std.string;

class LogTester {

	private string[] log;
	
	public string logOp;
	public ubyte logA;
	public ubyte logX;
	public ubyte logY;
	public ubyte logP;
	public ubyte logSP;
	public ushort logPC;
	
	this(string filename) {
		log = readText("testRoms/nestest.log").split("\n");
	}
	
	public static bool test(string romFilename, string logFilename) {
		Nes nes = new Nes();
		Cpu cpu = nes.cpu;
		Rom rom = new Rom(romFilename);
		nes.loadRom(rom);
		nes.powerUp();
		return test(logFilename, nes);
	}
	
	public static bool test(string logFilename, Nes nes) {
		LogTester logTester = new LogTester(logFilename);
		Cpu cpu = nes.cpu;
		string lastDebugLine;
		for(int i = 0; i < 8991; i++) {
			cpu.loadNextInstruction();
			string newDebugLine = to!string(cpu.getInstructions() + 1) ~ ": \t" ~ to!string(cpu.getCycles());
			newDebugLine ~= "\t" ~ to!string(cpu.getOperation()) ~ "\t" ~ to!string(cpu.getMode()) ~ "\t" ~ to!string(cpu.getInterruption());
			newDebugLine ~= format!" \t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x"(cpu.getOpcode(), cpu.getImmediate(), cpu.getAddress(), cpu.getPC(), cpu.getSP(), cpu.getA(), cpu.getX(), cpu.getY(), cpu.getP());
			if(!logTester.validate(cpu.getInstructions(), cpu.getPC(), cpu.getOperation(), cpu.getA(), cpu.getX(), cpu.getY(), cpu.getP(), cpu.getSP())) {
				writeln("\n\tcycles\top\tmode\tint\topcode\timm\taddr\tpc\tsp\ta\tx\ty\tp");
				writeln(lastDebugLine);
				write("\033[1;31m");
				writeln(newDebugLine);
				write("\033[0m");
				writefln("expected:\t%s\t\t\t\t\t\t%x\t%x\t%x\t%x\t%x\t%x", logTester.logOp, logTester.logPC, logTester.logSP, logTester.logA, logTester.logX, logTester.logY, logTester.logP);
				return false;
			}
			lastDebugLine = newDebugLine;
			cpu.executeInstruction();
		}
		return true;
	}

	public bool validate(int instructionNumber, ushort pc, Op operation, ubyte a, ubyte x, ubyte y, ubyte p, ubyte sp) {
		parseLine(instructionNumber);
		if(pc != logPC) return false;
		if(to!string(operation) != logOp) return false;
		if(a != logA) return false;
		if(x != logX) return false;
		if(y != logY) return false;
		if(p != logP) return false;
		if(sp != logSP) return false;
		return true;
	}
	
	private void parseLine(int lineNumber) {
		string line = log[lineNumber];
		logOp = matchFirst(line, r"(\s|\*)\S\S\S(\s)").hit[1..4];
		logA = matchFirst(line, r"A:\S\S").hit[2..4].to!ubyte(16);
		logX = matchFirst(line, r"X:\S\S").hit[2..4].to!ubyte(16);
		logY = matchFirst(line, r"Y:\S\S").hit[2..4].to!ubyte(16);
		logP = matchFirst(line, r"P:\S\S").hit[2..4].to!ubyte(16);
		logSP = matchFirst(line, r"SP:\S\S").hit[3..5].to!ubyte(16);
		logPC = line[0..4].to!ushort(16);
		if(logOp == "ISB") logOp = "ISC";
	}
}
