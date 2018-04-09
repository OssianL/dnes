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
	
	public string lastDebugLine;
	
	this(string filename) {
		log = readText(filename).split("\n");
	}
	
	public static bool test(string romFilename, string logFilename) {
		Nes nes = new Nes();
		Rom rom = new Rom(romFilename);
		nes.loadRom(rom);
		nes.powerUp();
		return test(logFilename, nes);
	}
	
	public static bool test(string logFilename, Nes nes) {
		LogTester logTester = new LogTester(logFilename);
		while(nes.cpu.getInstructions() < (logTester.getLogLength() - 1)) {
			if(!logTester.validateCpuStep(nes.cpu)) return false;
			nes.step();
		}
		return true;
	}
	
	private bool validateCpuStep(Cpu cpu) {
		if(cpu.isStalling() || cpu.getInterruption() != Interruption.NONE) return true;
		string newDebugLine = buildCpuStateString(cpu);
		if(!validateCpuState(cpu)) {
			printDebugMessage(lastDebugLine, newDebugLine);
			return false;
		}
		lastDebugLine = newDebugLine;
		return true;
	}

	private bool validateCpuState(Cpu cpu) {
		parseLine(cpu.getInstructions());
		if(cpu.getPC() != logPC) return false;
		if(to!string(cpu.getOperation()) != logOp) return false;
		if(cpu.getA() != logA) return false;
		if(cpu.getX() != logX) return false;
		if(cpu.getY() != logY) return false;
		if(cpu.getP() != logP) return false;
		if(cpu.getSP() != logSP) return false;
		return true;
	}
	
	private ulong getLogLength() {
		return log.length;
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
	
	private string buildCpuStateString(Cpu cpu) {
		string newDebugLine = to!string(cpu.getInstructions() + 1) ~ ": \t" ~ to!string(cpu.getCycles());
		newDebugLine ~= "\t" ~ to!string(cpu.getOperation()) ~ "\t" ~ to!string(cpu.getMode()) ~ "\t" ~ to!string(cpu.getInterruption());
		newDebugLine ~= format!" \t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x"(cpu.getOpcode(), cpu.getImmediate(), cpu.getAddress(), cpu.getPC(), cpu.getSP(), cpu.getA(), cpu.getX(), cpu.getY(), cpu.getP());
		return newDebugLine;
	}
	
	private void printDebugMessage(string lastDebugLine,string newDebugLine) {
		writeln("\n\tcycles\top\tmode\tint\topcode\timm\taddr\tpc\tsp\ta\tx\ty\tp");
		writeln(lastDebugLine);
		write("\033[1;31m");
		writeln(newDebugLine);
		write("\033[0m");
		writefln("expected:\t%s\t\t\t\t\t\t%x\t%x\t%x\t%x\t%x\t%x", logOp, logPC, logSP, logA, logX, logY, logP);
	}
}

/*
unittest {
	Nes nes = new Nes();
	Cpu cpu = nes.cpu;
	Rom rom = new Rom("testRoms/nestest.nes");
	nes.loadRom(rom);
	nes.powerUp();
	cpu.setPC(0xc000);
	cpu.loadNextInstruction();
	cpu.setInterruption(Interruption.NONE);
	writeln("jee");
	assert(LogTester.test("testRoms/nestest.log", nes), "nestest failed");
}
*/

/*
unittest {
	assert(LogTester.test("gitignore/donkeykong.nes", "testRoms/donkeykongstart.log"), "donkey kong start failed");
}
*/

