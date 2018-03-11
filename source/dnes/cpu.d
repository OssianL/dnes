module dnes.cpu;

import dnes.cpumemory;
import dnes.nes;
import main;
import std.stdio;
import std.format;
import std.conv;

enum Op {
	ADC, AND, ASL, BCC, BCS, BEQ, BIT, BMI, BNE, BPL,
	BRK, BVC, BVS, CLC, CLD, CLI, CLV, CMP, CPX, CPY,
	DEC, DEX, DEY, EOR, INC, INX, INY, JMP, JSR, LDA,
	LDX, LDY, LSR, NOP, ORA, PHA, PHP, PLA, PLP, ROL,
	ROR, RTI, RTS, SBC, SEC, SED, SEI, STA, STX, STY,
	TAX, TAY, TSX, TXA, TXS, TYA,
	/*unofficial opcodes:*/
	LAX, SAX, DCP, ISC, SLO, RLA, SRE, RRA
}

enum Mode {
	IMP, //implicit
	ACC, //accumulator
	IMM, //immediate
	ZPG, //zero page
	ZPX, //zero page x
	ZPY, //zero page y
	REL, //relative
	ABS, //absolute
	ABX, //absolute x
	ABY, //absolute y
	IND, //indirect
	INX, //indexed indirect
	INY  //indirect indexed
}

enum Interruption {
	NONE = 0, IRQ = 1, NMI = 2, RESET = 3
}

//operation of each opcode
const Op[256] opcodeOperation = [
//0		1		2		3		4		5		6		7		8		9		A		B		C		D		E		F
Op.BRK, Op.ORA, Op.NOP, Op.SLO, Op.NOP, Op.ORA, Op.ASL, Op.SLO, Op.PHP, Op.ORA, Op.ASL, Op.NOP, Op.NOP, Op.ORA, Op.ASL, Op.SLO, //0
Op.BPL, Op.ORA, Op.NOP, Op.SLO, Op.NOP, Op.ORA, Op.ASL, Op.SLO, Op.CLC, Op.ORA, Op.NOP, Op.SLO, Op.NOP, Op.ORA, Op.ASL, Op.SLO,	//1
Op.JSR, Op.AND, Op.NOP, Op.RLA, Op.BIT, Op.AND, Op.ROL, Op.RLA, Op.PLP, Op.AND, Op.ROL, Op.NOP, Op.BIT, Op.AND, Op.ROL, Op.RLA,	//2
Op.BMI, Op.AND, Op.NOP, Op.RLA, Op.NOP, Op.AND, Op.ROL, Op.RLA, Op.SEC, Op.AND, Op.NOP, Op.RLA, Op.NOP, Op.AND, Op.ROL, Op.RLA,	//3
Op.RTI, Op.EOR, Op.NOP, Op.SRE, Op.NOP, Op.EOR, Op.LSR, Op.SRE, Op.PHA, Op.EOR, Op.LSR, Op.NOP, Op.JMP, Op.EOR, Op.LSR, Op.SRE,	//4
Op.BVC, Op.EOR, Op.NOP, Op.SRE, Op.NOP, Op.EOR, Op.LSR, Op.SRE, Op.CLI, Op.EOR, Op.NOP, Op.SRE, Op.NOP, Op.EOR, Op.LSR, Op.SRE,	//5
Op.RTS, Op.ADC, Op.NOP, Op.RRA, Op.NOP, Op.ADC, Op.ROR, Op.RRA, Op.PLA, Op.ADC, Op.ROR, Op.NOP, Op.JMP, Op.ADC, Op.ROR, Op.RRA,	//6
Op.BVS, Op.ADC, Op.NOP, Op.RRA, Op.NOP, Op.ADC, Op.ROR, Op.RRA, Op.SEI, Op.ADC, Op.NOP, Op.RRA, Op.NOP, Op.ADC, Op.ROR, Op.RRA,	//7
Op.NOP, Op.STA, Op.NOP, Op.SAX, Op.STY, Op.STA, Op.STX, Op.SAX, Op.DEY, Op.NOP, Op.TXA, Op.NOP, Op.STY, Op.STA, Op.STX, Op.SAX,	//8
Op.BCC, Op.STA, Op.NOP, Op.NOP, Op.STY, Op.STA, Op.STX, Op.SAX, Op.TYA, Op.STA, Op.TXS, Op.NOP, Op.NOP, Op.STA, Op.NOP, Op.NOP,	//9
Op.LDY, Op.LDA, Op.LDX, Op.LAX, Op.LDY, Op.LDA, Op.LDX, Op.LAX, Op.TAY, Op.LDA, Op.TAX, Op.LAX, Op.LDY, Op.LDA, Op.LDX, Op.LAX,	//A
Op.BCS, Op.LDA, Op.NOP, Op.LAX, Op.LDY, Op.LDA, Op.LDX, Op.LAX, Op.CLV, Op.LDA, Op.TSX, Op.NOP, Op.LDY, Op.LDA, Op.LDX, Op.LAX,	//B
Op.CPY, Op.CMP, Op.NOP, Op.DCP, Op.CPY, Op.CMP, Op.DEC, Op.DCP, Op.INY, Op.CMP, Op.DEX, Op.NOP, Op.CPY, Op.CMP, Op.DEC, Op.DCP,	//C
Op.BNE, Op.CMP, Op.NOP, Op.DCP, Op.NOP, Op.CMP, Op.DEC, Op.DCP, Op.CLD, Op.CMP, Op.NOP, Op.DCP, Op.NOP, Op.CMP, Op.DEC, Op.DCP,	//D
Op.CPX, Op.SBC, Op.NOP, Op.ISC, Op.CPX, Op.SBC, Op.INC, Op.ISC, Op.INX, Op.SBC, Op.NOP, Op.SBC, Op.CPX, Op.SBC, Op.INC, Op.ISC,	//E
Op.BEQ, Op.SBC, Op.NOP, Op.ISC, Op.NOP, Op.SBC, Op.INC, Op.ISC, Op.SED, Op.SBC, Op.NOP, Op.ISC, Op.NOP, Op.SBC, Op.INC, Op.ISC	//F
];

//memory access mode for each opcode
const Mode[256] opcodeAddressingMode = [
//0       1         2         3         4         5         6         7         8         9         A         B         C         D         E         F
Mode.IMP, Mode.INX, Mode.IMP, Mode.INX, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMM, Mode.ACC, Mode.IMM, Mode.ABS, Mode.ABS, Mode.ABS, Mode.ABS, //0
Mode.REL, Mode.INY, Mode.IMP, Mode.INY, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.ABY, Mode.IMP, Mode.ABY, Mode.ABX, Mode.ABX, Mode.ABX, Mode.ABX, //1
Mode.ABS, Mode.INX, Mode.IMP, Mode.INX, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMM, Mode.ACC, Mode.IMM, Mode.ABS, Mode.ABS, Mode.ABS, Mode.ABS, //2
Mode.REL, Mode.INY, Mode.IMP, Mode.INY, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.ABY, Mode.IMP, Mode.ABY, Mode.ABX, Mode.ABX, Mode.ABX, Mode.ABX, //3
Mode.IMP, Mode.INX, Mode.IMP, Mode.INX, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMM, Mode.ACC, Mode.IMM, Mode.ABS, Mode.ABS, Mode.ABS, Mode.ABS, //4
Mode.REL, Mode.INY, Mode.IMP, Mode.INY, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.ABY, Mode.IMP, Mode.ABY, Mode.ABX, Mode.ABX, Mode.ABX, Mode.ABX, //5
Mode.IMP, Mode.INX, Mode.IMP, Mode.INX, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMM, Mode.ACC, Mode.IMM, Mode.IND, Mode.ABS, Mode.ABS, Mode.ABS, //6
Mode.REL, Mode.INY, Mode.IMP, Mode.INY, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.ABY, Mode.IMP, Mode.ABY, Mode.ABX, Mode.ABX, Mode.ABX, Mode.ABX, //7
Mode.IMM, Mode.INX, Mode.IMP, Mode.INX, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMP, Mode.IMM, Mode.ABS, Mode.ABS, Mode.ABS, Mode.ABS, //8
Mode.REL, Mode.INY, Mode.IMP, Mode.INY, Mode.ZPX, Mode.ZPX, Mode.ZPY, Mode.ZPY, Mode.IMP, Mode.ABY, Mode.IMP, Mode.ABY, Mode.ABX, Mode.ABX, Mode.ABY, Mode.ABY, //9
Mode.IMM, Mode.INX, Mode.IMM, Mode.INX, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMM, Mode.IMP, Mode.IMM, Mode.ABS, Mode.ABS, Mode.ABS, Mode.ABS, //A
Mode.REL, Mode.INY, Mode.IMP, Mode.INY, Mode.ZPX, Mode.ZPX, Mode.ZPY, Mode.ZPY, Mode.IMP, Mode.ABY, Mode.IMP, Mode.ABY, Mode.ABX, Mode.ABX, Mode.ABY, Mode.ABY, //B
Mode.IMM, Mode.INX, Mode.IMP, Mode.INX, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMM, Mode.IMP, Mode.IMM, Mode.ABS, Mode.ABS, Mode.ABS, Mode.ABS, //C
Mode.REL, Mode.INY, Mode.IMP, Mode.INY, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.ABY, Mode.IMP, Mode.ABY, Mode.ABX, Mode.ABX, Mode.ABX, Mode.ABX, //D
Mode.IMM, Mode.INX, Mode.IMP, Mode.INX, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMM, Mode.IMP, Mode.IMM, Mode.ABS, Mode.ABS, Mode.ABS, Mode.ABS, //E
Mode.REL, Mode.INY, Mode.IMP, Mode.INY, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.ABY, Mode.IMP, Mode.ABY, Mode.ABX, Mode.ABX, Mode.ABX, Mode.ABX  //F
];

//base cycle costs for each opcode
const byte[256] cycleCosts = [
  //0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
	7, 6, 2, 8, 2, 3, 5, 5, 3, 2, 2, 2, 2, 4, 6, 6, //0
	2, 5, 2, 8, 2, 4, 6, 6, 2, 4, 2, 7, 2, 4, 7, 7, //1
	6, 6, 2, 8, 3, 3, 5, 5, 4, 2, 2, 2, 4, 4, 6, 6, //2
	2, 5, 2, 8, 2, 4, 6, 6, 2, 4, 2, 7, 2, 4, 7, 7, //3
	6, 6, 2, 8, 2, 3, 5, 5, 3, 2, 2, 2, 3, 4, 6, 6, //4
	2, 5, 2, 8, 2, 4, 6, 6, 2, 4, 2, 7, 2, 4, 7, 7, //5
	6, 6, 2, 8, 2, 3, 5, 5, 4, 2, 2, 2, 5, 4, 6, 6, //6
	2, 5, 2, 8, 2, 4, 6, 6, 2, 4, 2, 7, 2, 4, 7, 7, //7
	2, 6, 2, 6, 3, 3, 3, 3, 2, 2, 2, 2, 4, 4, 4, 4, //8
	2, 6, 2, 2, 4, 4, 4, 4, 2, 5, 2, 2, 2, 5, 2, 2, //9
	2, 6, 2, 6, 3, 3, 3, 3, 2, 2, 2, 2, 4, 4, 4, 4, //A
	2, 5, 2, 5, 4, 4, 4, 4, 2, 4, 2, 2, 4, 4, 4, 4, //B
	2, 6, 2, 8, 3, 3, 5, 5, 2, 2, 2, 2, 4, 4, 6, 6, //C
	2, 5, 2, 8, 2, 4, 6, 6, 2, 4, 2, 7, 2, 4, 7, 7, //D
	2, 6, 2, 8, 3, 3, 5, 5, 2, 2, 2, 3, 4, 4, 6, 6, //E
	2, 5, 2, 8, 2, 4, 6, 6, 2, 4, 2, 7, 2, 4, 7, 7  //F
];

class Cpu {
	
	private Nes nes;
	private void delegate(Mode, ubyte, ushort)[Op] operationDelegates;
	private CpuMemory memory;
	
	//registers
	private ushort pc; //program counter
	private ubyte sp; //stack pointer
	private ubyte a; //accumulator
	private ubyte x; //index register X
	private ubyte y; //index register Y
	private ubyte p; //flags: negative, overflow, none, break command, decimal mode, interrupts disabled, zero, carry
	
	private ubyte opcode;
	private ubyte immediate;
	private ushort address;
	private Op operation;
	private Mode mode;
	
	private uint cycles;
	private uint instructions = 1;
	
	private Interruption interruption = Interruption.NONE;
	private bool brkInterruption = false; //true if interruption caused by brk
	enum irqAddress = 0xFFFE;
	enum nmiAddress = 0xFFFA;
	enum resetAddress = 0xFFFC;
	
	enum negativeFlagMask = 0B10000000;
	enum overflowFlagMask = 0B01000000;
	enum breakFlagMask = 0B00010000;
	enum decimalFlagMask = 0B00001000; //can be set but is ignored
	enum interruptsDisabledFlagMask = 0B00000100;
	enum zeroFlagMask = 0B00000010;
	enum carryFlagMask = 0B00000001;
	enum signBitMask = 0b10000000;
	
	enum stackAddress = 0x0100;
	
	this(Nes nes) {
		this.nes = nes;
		this.memory = new CpuMemory(nes);
		operationDelegates = [
			Op.ADC:&adc, Op.AND:&and, Op.ASL:&asl, Op.BCC:&bcc, Op.BCS:&bcs, Op.BEQ:&beq, Op.BIT:&bit, Op.BMI:&bmi,
			Op.BNE:&bne, Op.BPL:&bpl, Op.BRK:&brk, Op.BVC:&bvc, Op.BVS:&bvs, Op.CLC:&clc, Op.CLD:&cld, Op.CLI:&cli,
			Op.CLV:&clv, Op.CMP:&cmp, Op.CPX:&cpx, Op.CPY:&cpy, Op.DEC:&dec, Op.DEX:&dex, Op.DEY:&dey, Op.EOR:&eor,
			Op.INC:&inc, Op.INX:&inx, Op.INY:&iny, Op.JMP:&jmp, Op.JSR:&jsr, Op.LDA:&lda, Op.LDX:&ldx, Op.LDY:&ldy,
			Op.LSR:&lsr, Op.NOP:&nop, Op.ORA:&ora, Op.PHA:&pha, Op.PHP:&php, Op.PLA:&pla, Op.PLP:&plp, Op.ROL:&rol,
			Op.ROR:&ror, Op.RTI:&rti, Op.RTS:&rts, Op.SBC:&sbc, Op.SEC:&sec, Op.SED:&sed, Op.SEI:&sei, Op.STA:&sta,
			Op.STX:&stx, Op.STY:&sty, Op.TAX:&tax, Op.TAY:&tay, Op.TSX:&tsx, Op.TXA:&txa, Op.TXS:&txs, Op.TYA:&tya,
			//unofficial opcodes:
			Op.LAX:&lax, Op.SAX:&sax, Op.DCP:&dcp, Op.ISC:&isc, Op.SLO:&slo, Op.RLA:&rla, Op.SRE:&sre, Op.RRA:&rra
		];
	}
	
	public void powerUp() {
		writeln("cpu power up");
		p = 0x36;
		a = 0;
		x = 0;
		y = 0;
		sp = 0xfd;
		raiseInterruption(Interruption.RESET);
	}
	
	public void reset() {
		writeln("cpu reset");
		sp -= 3;
		p |= interruptsDisabledFlagMask;
		raiseInterruption(Interruption.RESET);
	}
	
	public void loadNextInstruction() {
		opcode = memory.read(pc); //first byte
		immediate = memory.read(pc + 1); //second byte, immediate value or zpg address
		address = memory.read16(pc + 1); //second and third byte, usually address
		operation = opcodeOperation[opcode];
		mode = opcodeAddressingMode[opcode];
	}
	
	public void step() {
		if(interruption != Interruption.NONE) jumpToInterruptionHandler();
		else {
			instructions++;
			addPC(getInstructionSize(mode));
			operationDelegates[operation](mode, immediate, address);
			addCycles(getCycleCost(opcode) + memory.getPageCrossedValue());
			memory.clearPageCrossed();
		}
	}
	
	public void setA(ubyte a) {
		this.a = a;
	}
	
	public void setA(int a) {
		setA(cast(ubyte) a);
	}
	
	public ubyte getA() {
		return this.a;
	}
	
	public void setX(ubyte x) {
		this.x = x;
	}
	
	public void setX(int x) {
		setX(cast(ubyte) x);
	}
	
	public ubyte getX() {
		return this.x;
	}
	
	public void setY(ubyte y) {
		this.y = y;
	}
	
	public void setY(int y) {
		setY(cast(ubyte) y);
	}
	
	public ubyte getY() {
		return this.y;
	}
	
	public void setPC(ushort pc) {
		this.pc = pc;
	}
	
	public void setPC(int pc) {
		setPC(cast(ushort) pc);
	}
	
	public ushort getPC() {
		return this.pc;
	}
	
	public void addPC(int increment) {
		setPC(getPC() + increment);
	}
	
	public void setSP(ubyte sp) {
		this.sp = sp;
	}
	
	public void setSP(int sp) {
		setSP(cast(ubyte) sp);
	}
	
	public ubyte getSP() {
		return this.sp;
	}
	
	public ubyte getP() {
		return this.p;
	}
	
	public void setP(ubyte p) {
		this.p = p;
	}
	
	public bool getCarryFlag() {
		return cast(bool) (p & carryFlagMask);
	}
	
	public ubyte getCarryFlagValue() {
		if(getCarryFlag()) return 1;
		else return 0;
	}
	
	public void setCarryFlag(bool carry) {
		if(carry) p = cast(ubyte) ((p & ~carryFlagMask) + carryFlagMask);
		else p &= ~carryFlagMask;
	}
	
	public void updateCarryFlag(int number) {
		if(number > 0xFF) setCarryFlag(true);
		else setCarryFlag(false);
	}
	
	public bool getZeroFlag() {
		return cast(bool) (p & zeroFlagMask);
	}
	
	public void setZeroFlag(bool zero) {
		if(zero) p |= zeroFlagMask;
		else p &= ~zeroFlagMask;
	}
	
	public void updateZeroFlag(int zero) {
		if(zero == 0) setZeroFlag(true);
		else setZeroFlag(false);
	}
	
	public bool getOverflowFlag() {
		return cast(bool) (p & overflowFlagMask);
	}
	
	public void setOverflowFlag(bool overflow) {
		if(overflow) p |= overflowFlagMask;
		else p &= (~overflowFlagMask);
	}
	
	public void updateOverflowFlag(uint value1, uint value2, uint result) {
		setOverflowFlag(cast(bool) ((value1 ^ result) & (value2 ^ result) & signBitMask));
	}
	
	public bool getNegativeFlag() {
		return cast(bool) (p & negativeFlagMask);
	}
	
	public void setNegativeFlag(bool negative) {
		if(negative) p = cast(ubyte) ((p & ~negativeFlagMask) + negativeFlagMask);
		else p &= ~negativeFlagMask;
	}
	
	public void updateNegativeFlag(int value) {
		if(value & signBitMask) setNegativeFlag(true);
		else setNegativeFlag(false);
	}
	
	public bool getInterruptsDisabledFlag() {
		return cast(bool) (p & interruptsDisabledFlagMask);
	}
	
	public void setInterruptsDisabledFlag(bool interruptsDisabled) {
		if(interruptsDisabled) p = cast(ubyte) ((p & ~interruptsDisabledFlagMask) + interruptsDisabledFlagMask);
		else p &= ~interruptsDisabledFlagMask;
	}
	
	public bool getDecimalModeFlag() {
		return cast(bool) (p & decimalFlagMask);
	}
	
	public void setDecimalModeFlag(bool decimalMode) {
		if(decimalMode) p |= decimalFlagMask;
		else p &= ~decimalFlagMask;
	}
	
	public void setBreakCommandFlag(bool breakCommand) {
		if(breakCommand) p = cast(ubyte) ((p & ~breakFlagMask) + breakFlagMask);
		else p &= ~breakFlagMask;
	}
	
	public bool getBreakCommandFlag() {
		return cast(bool) (p & breakFlagMask);
	}
	
	public uint getCycles() {
		return cycles;
	}
	
	public int getInstructions() {
		return instructions;
	}
	
	public ubyte getOpcode() {
		return opcode;
	}
	
	public ubyte getImmediate() {
		return immediate;
	}
	
	public ushort getAddress() {
		return address;
	}
	
	public Op getOperation() {
		return operation;
	}
	
	public Mode getMode() {
		return mode;
	}
	
	public Interruption getInterruption() {
		return interruption;
	}
	
	public void setInterruption(Interruption interruption) {
		this.interruption = interruption;
	}
	
	public void raiseInterruption(Interruption newInterrupion) {
		if(newInterrupion > this.interruption) {
			if(newInterrupion == Interruption.IRQ && !getInterruptsDisabledFlag()) {
				this.interruption = newInterrupion;
			}
			else if(newInterrupion != Interruption.IRQ) this.interruption = newInterrupion;
		}
	}
	
	public CpuMemory getMemory() {
		return memory;
	}

	public void stall(int cycles) {
		assert(false, "TODO stealCycles"); //TODO
	}
	
	/*
	Add with Carry
	This instruction adds the contents of a memory location to the accumulator together with the carry bit.
	If overflow occurs the carry bit is set, this enables multiple byte addition to be performed.
	*/
	public void adc(Mode mode, ubyte immediate, ushort address) {
		uint value = memory.read(mode, immediate, address);
		uint result = value + a + getCarryFlagValue();
		updateOverflowFlag(a, value, result);
		setA(result);
		updateZeroFlag(a);
		updateCarryFlag(result);
		updateNegativeFlag(result);
	}
	
	/*
	Logical AND
	A logical AND is performed, bit by bit, on the accumulator contents using the contents of a byte of memory.
	*/
	public void and(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setA(value & getA());
		updateZeroFlag(getA());
		updateNegativeFlag(getA());
	}
	
	/*
	Arithmetic Shift Left
	This operation shifts all the bits of the accumulator or memory contents one bit left. Bit 0 is set to 0 and bit 7
	is placed in the carry flag. The effect of this operation is to multiply the memory contents by 2 (ignoring 2's
	complement considerations), setting the carry if the result will not fit in 8 bits.
	*/
	public void asl(Mode mode, ubyte immediate, ushort address) {
		int result = memory.read(mode, immediate, address);
		setCarryFlag(cast(bool) (result & 0b10000000)); //set to old bit 7
		result <<= 1;
		memory.write(mode, immediate, address, cast(ubyte) result);
		updateZeroFlag(cast(ubyte) result);
		updateNegativeFlag(result);
	}
	
	/*
	Branch if Carry Clear
	If the carry flag is clear then add the relative displacement to the program counter to cause a branch to a new
	location.
	*/
	public void bcc(Mode mode, ubyte immediate, ushort address) {
		if(!getCarryFlag()) {
			byte relativeAddress = cast(byte) immediate;
			branch(relativeAddress);
		}
	}
	
	/*
	Branch if Carry Set
	If the carry flag is set then add the relative displacement to the program counter to cause a branch to a new
	location.
	*/
	public void bcs(Mode mode, ubyte immediate, ushort address) {
		if(getCarryFlag()) {
			byte relativeAddress = cast(byte) immediate;
			branch(relativeAddress);
		}
	}
	
	/*
	Branch if Equal
	If the zero flag is set then add the relative displacement to the program counter to cause a branch to a new
	location.
	*/
	public void beq(Mode mode, ubyte immediate, ushort address) {
		if(getZeroFlag()) {
			byte relativeAddress = cast(byte) immediate;
			branch(relativeAddress);
		}
	}
	
	/*
	Bit Test
	This instructions is used to test if one or more bits are set in a target memory location. The mask pattern in A is
	ANDed with the value in memory to set or clear the zero flag, but the result is not kept. Bits 7 and 6 of the value
	from memory are copied into the N and V flags.
	*/
	public void bit(Mode mode, ubyte immediate, ushort address) {
		uint value = memory.read(mode, immediate, address);
		uint result = value & a;
		updateZeroFlag(result);
		setOverflowFlag(cast(bool) (value & overflowFlagMask));
		updateNegativeFlag(value);
	}
	
	/*
	Branch if Minus
	If the negative flag is set then add the relative displacement to the program counter to cause a branch to a new
	location.
	*/
	public void bmi(Mode mode, ubyte immediate, ushort address) {
		if(getNegativeFlag()) {
			byte relativeAddress = cast(byte) immediate;
			branch(relativeAddress);
		}
	}
	
	/*
	Branch if Not Equal
	If the zero flag is clear then add the relative displacement to the program counter to cause a branch to a new
	location.
	*/
	public void bne(Mode mode, ubyte immediate, ushort address) {
		if(!getZeroFlag()) {
			byte relativeAddress = cast(byte) immediate;
			branch(relativeAddress);
		}
	}
	
	/*
	Branch if Positive
	If the negative flag is clear then add the relative displacement to the program counter to cause a branch to a new
	location.
	*/
	public void bpl(Mode mode, ubyte immediate, ushort address) {
		if(!getNegativeFlag()) {
			byte relativeAddress = cast(byte) immediate;
			branch(relativeAddress);
		}
	}
	
	/*
	Force Interrupt
	The BRK instruction forces the generation of an interrupt request. The program counter and processor status are
	pushed on the stack then the IRQ interrupt vector at $FFFE/F is loaded into the PC and the break flag in the status
	set to one.
	*/
	public void brk(Mode mode, ubyte immediate, ushort address) {
		raiseInterruption(Interruption.IRQ);
		brkInterruption = true;
	}
	
	/*
	Branch if Overflow Clear
	If the overflow flag is clear then add the relative displacement to the program counter to cause a branch to a new
	location.
	*/
	public void bvc(Mode mode, ubyte immediate, ushort address) {
		if(!getOverflowFlag()) {
			byte relativeAddress = cast(byte) immediate;
			branch(relativeAddress);
		}
	}
	
	/*
	Branch if Overflow Set
	If the overflow flag is set then add the relative displacement to the program counter to cause a branch to a new
	location.
	*/
	public void bvs(Mode mode, ubyte immediate, ushort address) {
		if(getOverflowFlag()) {
			byte relativeAddress = cast(byte) immediate;
			branch(relativeAddress);
		}
	}
	
	/*
	Clear Carry Flag
	Set the carry flag to zero.
	*/
	public void clc(Mode mode, ubyte immediate, ushort address) {
		setCarryFlag(false);
	}
	
	/*
	Clear Decimal Mode
	Not used in nes.
	*/
	public void cld(Mode mode, ubyte immediate, ushort address) {
		setDecimalModeFlag(false);
	}
	
	/*
	Clear Interrupt Disable
	Clears the interrupt disable flag allowing normal interrupt requests to be serviced.
	*/
	public void cli(Mode mode, ubyte immediate, ushort address) {
		setInterruptsDisabledFlag(false);
	}
	
	/*
	Clear Overflow Flag
	Clears the overflow flag.
	*/
	public void clv(Mode mode, ubyte immediate, ushort address) {
		setOverflowFlag(false);
	}
	
	/*
	Compare
	This instruction compares the contents of the accumulator with another memory held value and sets the zero and
	carry flags as appropriate.
	*/
	public void cmp(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setCarryFlag(getA() >= value);
		setZeroFlag(getA() == value);
		updateNegativeFlag(getA() - value);
	}
	
	/*
	CPX - Compare X Register
	This instruction compares the contents of the X register with another memory held value and sets the zero and
	carry flags as appropriate.
	*/
	public void cpx(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setCarryFlag(getX() >= value);
		setZeroFlag(getX() == value);
		updateNegativeFlag(getX() - value);
	}
	
	/*
	Compare Y Register
	This instruction compares the contents of the Y register with another memory held value and sets the zero and carry
	flags as appropriate.
	*/
	public void cpy(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setCarryFlag(getY() >= value);
		setZeroFlag(getY() == value);
		updateNegativeFlag(cast(ubyte) (getY() - value));
	}
	
	/* UNOFFICIAL
	Equivalent to DEC value then CMP value, except supporting more addressing modes. LDA #$FF followed by DCP can be
	used to check if the decrement underflows, which is useful for multi-byte decrements.
	*/
	public void dcp(Mode mode, ubyte immediate, ushort address) {
		dec(mode, immediate, address);
		cmp(mode, immediate, address);
	}
	
	/*
	Decrement Memory
	Subtracts one from the value held at a specified memory location setting the zero and negative flags as appropriate.
	*/
	public void dec(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		value--;
		memory.write(mode, immediate, address, value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Decrement X Register
	Subtracts one from the X register setting the zero and negative flags as appropriate.
	*/
	public void dex(Mode mode, ubyte immediate, ushort address) {
		ubyte value = getX();
		value--;
		setX(value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Decrement Y Register
	Subtracts one from the Y register setting the zero and negative flags as appropriate.
	*/
	public void dey(Mode mode, ubyte immediate, ushort address) {
		ubyte value = getY();
		value--;
		setY(value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Exclusive OR
	An exclusive OR is performed, bit by bit, on the accumulator contents using the contents of a byte of memory.
	*/
	public void eor(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		value ^= getA();
		setA(value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Increment Memory
	Adds one to the value held at a specified memory location setting the zero and negative flags as appropriate.
	*/
	public void inc(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		value++;
		memory.write(mode, immediate, address, value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Increment X Register
	Adds one to the X register setting the zero and negative flags as appropriate.
	*/
	public void inx(Mode mode, ubyte immediate, ushort address) {
		ubyte value = getX();
		value++;
		setX(value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Increment Y Register
	Adds one to the Y register setting the zero and negative flags as appropriate.
	*/
	public void iny(Mode mode, ubyte immediate, ushort address) {
		ubyte value = getY();
		value++;
		setY(value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/* UNOFFICIAL
	Equivalent to INC value then SBC value, except supporting more addressing modes.
	*/
	public void isc(Mode mode, ubyte immediate, ushort address) {
		inc(mode, immediate, address);
		sbc(mode, immediate, address);
		setOverflowFlag(false); //nestest expects this. don't know why, no documentation.
	}
	
	/*
	Jump
	Sets the program counter to the address specified by the operand.
	*/
	public void jmp(Mode mode, ubyte immediate, ushort address) {
		if(mode == Mode.ABS) setPC(address);
		else if(mode == Mode.IND) {
			ushort newPC = memory.read(address);
			if((address & 0xff) == 0xff) address -= 0xff; //6502 bug: if second byte crosses page then it wraps around
			else address += 1;
			newPC |= memory.read(address) << 8;
			setPC(newPC);
		}
	}
	
	/*
	Jump to Subroutine
	The JSR instruction pushes the address (minus one) of the return point on to the stack and then sets the program
	counter to the target memory address.
	*/
	public void jsr(Mode mode, ubyte immediate, ushort address) {
		pushStack(cast(ushort) (getPC() - 1));
		setPC(address);
	}
	
	/*UNOFFICIAL
	Combined lda tax
	Shortcut for LDA value then TAX. Saves a byte and two cycles and allows use of the X register with the
	(d),Y addressing mode. Notice that the immediate is missing; the opcode that would have been LAX is affected by
	line noise on the data bus. MOS 6502: even the bugs have bugs.
	*/
	public void lax(Mode mode, ubyte immediate, ushort address) {
		lda(mode, immediate, address);
		tax(mode, immediate, address);
	}
	
	/*
	Load Accumulator
	Loads a byte of memory into the accumulator setting the zero and negative flags as appropriate.
	*/
	public void lda(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setA(value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Load X Register
	Loads a byte of memory into the X register setting the zero and negative flags as appropriate.
	*/
	public void ldx(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setX(value);
		updateZeroFlag(value);
		updateNegativeFlag(value); 
	}
	
	/*
	Load Y Register
	Loads a byte of memory into the Y register setting the zero and negative flags as appropriate.
	*/
	public void ldy(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setY(value);
		updateZeroFlag(value);
		updateNegativeFlag(value); 
	}
	
	/*
	Logical Shift Right
	Each of the bits in A or M is shift one place to the right. The bit that was in bit 0 is shifted into the carry
	flag. Bit 7 is set to zero.
	*/
	public void lsr(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setCarryFlag(cast(bool) (value & 1));
		value >>= 1;
		memory.write(mode, immediate, address, value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	No Operation
	The NOP instruction causes no changes to the processor other than the normal incrementing of the program counter to
	the next instruction.
	*/
	public void nop(Mode mode, ubyte immediate, ushort address) {
		
	}
	
	/*
	Logical Inclusive OR
	An inclusive OR is performed, bit by bit, on the accumulator contents using the contents of a byte of memory.
	*/
	public void ora(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		value |= getA();
		setA(value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Push Accumulator
	Pushes a copy of the accumulator on to the stack.
	*/
	public void pha(Mode mode, ubyte immediate, ushort address) {
		pushStack(getA());
	}
	
	/*
	Push Processor Status
	Pushes a copy of the status flags on to the stack.
	*/
	public void php(Mode mode, ubyte immediate, ushort address) {
		ubyte pushP = getP();
		pushP |= 0b00100000; //bit 5 always set
		pushP |= 0b00010000; //bit 4 set for brk and php
		pushStack(pushP);
	}
	/*
	Pull Accumulator
	Pulls an 8 bit value from the stack and into the accumulator. The zero and negative flags are set as appropriate.
	*/
	public void pla(Mode mode, ubyte immediate, ushort address) {
		setA(popStack());
		updateZeroFlag(getA());
		updateNegativeFlag(getA());
	}
	
	/*
	Pull Processor Status
	Pulls an 8 bit value from the stack and into the processor flags. The flags will take on new states as determined
	by the value pulled. break flag will be ignored
	*/
	public void plp(Mode mode, ubyte immediate, ushort address) {
		ubyte newP = popStack() & ~(breakFlagMask); //ignore break flag
		newP |= 0b00100000; //nestest requires bit 5 to be set when loading
		setP((getP() & breakFlagMask) | newP); //keep old break flag(?)
	}
	
	public void rla(Mode mode, ubyte immediate, ushort address) {
		rol(mode, immediate, address);
		and(mode, immediate, address);
	}
	
	/*
	Rotate Left
	Move each of the bits in either A or M one place to the left. Bit 0 is filled with the current value of the carry
	flag whilst the old bit 7 becomes the new carry flag value.
	*/
	public void rol(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		ubyte oldCarryFlag = getCarryFlagValue();
		setCarryFlag(cast(bool) (value & 0b10000000));
		value <<= 1;
		value = cast(ubyte) ((value & 0b11111110) + oldCarryFlag);
		memory.write(mode, immediate, address, value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Rotate Right
	Move each of the bits in either A or M one place to the right. Bit 7 is filled with the current value of the carry
	flag whilst the old bit 0 becomes the new carry flag value.
	*/
	public void ror(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		ubyte oldCarryFlag = getCarryFlagValue();
		setCarryFlag(cast(bool) (value & 0b00000001));
		value >>= 1;
		value |= (oldCarryFlag << 7);
		memory.write(mode, immediate, address, value);
		updateZeroFlag(cast(ubyte) value);
		updateNegativeFlag(value);
	}
	
	/* UNOFFICIAL
	Equivalent to ROR value then ADC value, except supporting more addressing modes.
	Essentially this computes A + value / 2, where value is 9-bit and the division is rounded up.
	*/
	public void rra(Mode mode, ubyte immediate, ushort address) {
		ror(mode, immediate, address);
		adc(mode, immediate, address);
	}
	
	/*
	Return from Interrupt
	The RTI instruction is used at the end of an interrupt processing routine. It pulls the processor flags (except break flag) from the
	stack followed by the program counter.
	*/
	public void rti(Mode mode, ubyte immediate, ushort address) {
		ubyte newP = popStack() & ~(breakFlagMask); //ignore break flag
		newP |= 0b00100000; //nestest requires bit 5 to be set when loading
		setP((getP() & breakFlagMask) | newP); //keep old break flag
		setPC(popStack16());
	}
	
	/*
	Return from Subroutine
	The RTS instruction is used at the end of a subroutine to return to the calling routine. It pulls the program
	counter (minus one) from the stack.
	*/
	public void rts(Mode mode, ubyte immediate, ushort address) {
		setPC(popStack16() + 1);
	}
	
	/* UNOFFICIAL
	Stores the bitwise AND of A and X. As with STA and STX, no flags are affected.
	*/
	public void sax(Mode mode, ubyte immediate, ushort address) {
		memory.write(mode, immediate, address, getA() & getX());
	}
	
	/*
	Subtract with Carry
	This instruction subtracts the contents of a memory location to the accumulator together with the not of the carry
	bit. If overflow occurs the carry bit is clear, this enables multiple byte subtraction to be performed.
	*/
	public void sbc(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		ubyte carry = getCarryFlag() ? 0 : 1;
		int signedResult = (cast(byte) (getA())) - value - carry; //TODO make this better
		uint result = getA() - value - carry;
		setA(result);
		updateZeroFlag(result);
		updateNegativeFlag(result);
		setOverflowFlag(getNegativeFlag() ? signedResult >= 0 : signedResult < 0);
		setCarryFlag(!(result > 0xff));
	}
	
	/*
	Set Carry Flag
	Set the carry flag to one.
	*/
	public void sec(Mode mode, ubyte immediate, ushort address) {
		setCarryFlag(true);
	}
	
	/*
	Set Decimal Flag
	Set the decimal mode flag to one.
	*/
	public void sed(Mode mode, ubyte immediate, ushort address) {
		setDecimalModeFlag(true);
	}
	
	/*
	Set Interrupt Disable
	Set the interrupt disable flag to one.
	*/
	public void sei(Mode mode, ubyte immediate, ushort address) {
		setInterruptsDisabledFlag(true);
	}
	
	/* UNOFFICIAL
	Equivalent to ASL value then ORA value, except supporting more addressing modes. LDA #0 followed by SLO is an
	efficient way to shift a variable while also loading it in A.
	*/
	public void slo(Mode mode, ubyte immediate, ushort address) {
		asl(mode, immediate, address);
		ora(mode, immediate, address);
	}
	
	/* UNOFFICIAL
	Equivalent to LSR value then EOR value, except supporting more addressing modes. LDA #0 followed by SRE is an
	efficient way to shift a variable while also loading it in A.
	*/
	public void sre(Mode mode, ubyte immediate, ushort address) {
		lsr(mode, immediate, address);
		eor(mode, immediate, address);
	}
	
	/*
	Store Accumulator
	Stores the contents of the accumulator into memory.
	*/
	public void sta(Mode mode, ubyte immediate, ushort address) {
		memory.write(mode, immediate, address, getA());
	}
	
	/*
	Store X Register
	Stores the contents of the X register into memory.
	*/
	public void stx(Mode mode, ubyte immediate, ushort address) {
		memory.write(mode, immediate, address, getX());
	}
	
	/*
	Store Y Register
	Stores the contents of the Y register into memory.
	*/
	public void sty(Mode mode, ubyte immediate, ushort address) {
		memory.write(mode, immediate, address, getY());
	}
	
	/*
	Transfer Accumulator to X
	Copies the current contents of the accumulator into the X register and sets the zero and negative flags as
	appropriate.
	*/
	public void tax(Mode mode, ubyte immediate, ushort address) {
		setX(getA());
		updateZeroFlag(getX());
		updateNegativeFlag(getX());
	}
	
	/*
	Transfer Accumulator to Y
	Copies the current contents of the accumulator into the Y register and sets the zero and negative flags as
	appropriate.
	*/
	public void tay(Mode mode, ubyte immediate, ushort address) {
		setY(getA());
		updateZeroFlag(getY());
		updateNegativeFlag(getY());
	}
	
	/*
	Transfer Stack Pointer to X
	Copies the current contents of the stack register into the X register and sets the zero and negative flags as
	appropriate.
	*/
	public void tsx(Mode mode, ubyte immediate, ushort address) {
		setX(getSP());
		updateZeroFlag(getX());
		updateNegativeFlag(getX());
	}
	
	/*
	Transfer X to Accumulator
	Copies the current contents of the X register into the accumulator and sets the zero and negative flags as
	appropriate.
	*/
	public void txa(Mode mode, ubyte immediate, ushort address) {
		setA(getX());
		updateZeroFlag(getA());
		updateNegativeFlag(getA());
	}
	
	/*
	Transfer X to Stack Pointer
	Copies the current contents of the X register into the stack register.
	*/
	public void txs(Mode mode, ubyte immediate, ushort address) {
		setSP(getX());
	}
	
	/*
	Transfer Y to Accumulator
	Copies the current contents of the Y register into the accumulator and sets the zero and negative flags as
	appropriate.
	*/
	public void tya(Mode mode, ubyte immediate, ushort address) {
		setA(getY());
		updateZeroFlag(getA());
		updateNegativeFlag(getA());
	}
	
	
	private void jumpToInterruptionHandler() {
		//writeln("jump to interruption handler. interruption: ", this.interruption);
		pushStack(getPC());
		pushStack(getP());
		if(brkInterruption) setBreakCommandFlag(true);
		brkInterruption = false;
		if(interruption == Interruption.IRQ) {
			setPC(memory.read16(irqAddress));
		}
		else if(interruption == Interruption.NMI) {
			setPC(memory.read16(nmiAddress));
		}
		else if(interruption == Interruption.RESET) {
			setPC(memory.read16(resetAddress));
			setSP(0xfd);//is this right?
		}
		setInterruptsDisabledFlag(true);
		this.interruption = Interruption.NONE;
	}
	
	private void branch(byte relativeAddress) {
		ushort newPC = cast(ushort) (getPC() + relativeAddress);
		if((getPC() & 0xFF00) == (newPC & 0xFF00)) addCycles(1);
		else addCycles(2);
		setPC(newPC);
	}
	
	private int getInstructionSize(Mode mode) {
		if(mode == Mode.ABS) return 3;
		else if(mode == Mode.ABX) return 3;
		else if(mode == Mode.ABY) return 3;
		else if(mode == Mode.ACC) return 1;
		else if(mode == Mode.IMM) return 2;
		else if(mode == Mode.IMP) return 1;
		else if(mode == Mode.IND) return 3;
		else if(mode == Mode.INX) return 2;
		else if(mode == Mode.INY) return 2;
		else if(mode == Mode.REL) return 2;
		else if(mode == Mode.ZPG) return 2;
		else if(mode == Mode.ZPX) return 2;
		else if(mode == Mode.ZPY) return 2;
		else assert(false, "hölöködöö");
	}
	
	private void addCycles(int amount) {
		this.cycles += amount;
	}
	
	private byte getCycleCost(ubyte opcode) {
		return cycleCosts[opcode];
	}
	
	private void pushStack(ubyte value) {
		//if(printDebug) writefln("push stack: %x", value);
		memory.write(stackAddress + getSP(), value);
		setSP(getSP() - 1);
	}
	
	private void pushStack(ushort value) {
		pushStack(cast(ubyte) (value >> 8));
		pushStack(cast(ubyte) value);
	}
	
	private ubyte popStack() {
		setSP(getSP() + 1);
		ubyte value = memory.read(stackAddress + getSP());
		//if(printDebug) writefln("pop stack: %x", value);
		return value;
	}
	
	private ushort popStack16() {
		ushort value = popStack();
		value |= cast(ushort) (popStack()) << 8;
		return value;
	}

}
