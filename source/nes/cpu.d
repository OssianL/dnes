import cpuMemory;

enum Op {
	ADC, AND, ASL, BCC, BCS, BEQ, BIT, BMI, BNE, BPL,
	BRK, BVC, BVS, CLC, CLD, CLI, CLV, CMP, CPX, CPY,
	DEC, DEX, DEY, EOR, INC, INX, INY, JMP, JSR, LDA,
	LDX, LDY, LSR, NOP, ORA, PHA, PHP, PLA, PLP, ROL,
	ROR, RTI, RTS, SBC, SEC, SED, SEI, STA, STX, STY,
	TAX, TAY, TSX, TXA, TXS, TYA, NON
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
Op.BRK, Op.ORA, Op.NON, Op.NON, Op.NON, Op.ORA, Op.ASL, Op.NON, Op.PHP, Op.ORA, Op.ASL, Op.NON, Op.NON, Op.ORA, Op.ASL, Op.NON, //0
Op.BPL, Op.NON, Op.NON, Op.NON, Op.NON, Op.ORA, Op.ASL, Op.NON, Op.CLC, Op.ORA, Op.NON, Op.NON, Op.NON, Op.ORA, Op.ASL, Op.NON,	//1
Op.JSR, Op.AND, Op.NON, Op.NON, Op.BIT, Op.AND, Op.ROL, Op.NON, Op.PLP, Op.AND, Op.ROL, Op.NON, Op.BIT, Op.AND, Op.ROL, Op.NON,	//2
Op.BMI, Op.AND, Op.NON, Op.NON, Op.NON, Op.AND, Op.ROL, Op.NON, Op.SEC, Op.AND, Op.NON, Op.NON, Op.NON, Op.AND, Op.ROL, Op.NON,	//3
Op.RTI, Op.EOR, Op.NON, Op.NON, Op.NON, Op.EOR, Op.LSR, Op.NON, Op.PHA, Op.EOR, Op.LSR, Op.NON, Op.JMP, Op.EOR, Op.LSR, Op.NON,	//4
Op.BVC, Op.EOR, Op.NON, Op.NON, Op.NON, Op.EOR, Op.LSR, Op.NON, Op.CLI, Op.EOR, Op.NON, Op.NON, Op.NON, Op.EOR, Op.LSR, Op.NON,	//5
Op.RTS, Op.ADC, Op.NON, Op.NON, Op.NON, Op.ADC, Op.ROR, Op.NON, Op.PLA, Op.ADC, Op.ROR, Op.NON, Op.JMP, Op.ADC, Op.ROR, Op.NON,	//6
Op.BVS, Op.ADC, Op.NON, Op.NON, Op.NON, Op.ADC, Op.ROR, Op.NON, Op.SEI, Op.ADC, Op.NON, Op.NON, Op.NON, Op.ADC, Op.ROR, Op.NON,	//7
Op.NON, Op.STA, Op.NON, Op.NON, Op.STY, Op.STA, Op.STX, Op.NON, Op.DEY, Op.NON, Op.TXA, Op.NON, Op.STY, Op.STA, Op.STX, Op.NON,	//8
Op.BCC, Op.STA, Op.NON, Op.NON, Op.STY, Op.STA, Op.STX, Op.NON, Op.TYA, Op.STA, Op.TXS, Op.NON, Op.NON, Op.STA, Op.NON, Op.NON,	//9
Op.LDA, Op.LDA, Op.LDX, Op.NON, Op.LDY, Op.LDA, Op.LDX, Op.NON, Op.TAY, Op.LDA, Op.TAX, Op.NON, Op.LDY, Op.LDA, Op.LDX, Op.NON,	//A
Op.BCS, Op.LDA, Op.NON, Op.NON, Op.LDY, Op.LDA, Op.LDX, Op.NON, Op.CLV, Op.LDA, Op.TSX, Op.NON, Op.LDY, Op.LDA, Op.LDA, Op.NON,	//B
Op.CPY, Op.CMP, Op.NON, Op.NON, Op.CPY, Op.CMP, Op.DEC, Op.NON, Op.INY, Op.CMP, Op.DEX, Op.NON, Op.CPY, Op.CMP, Op.DEC, Op.NON,	//C
Op.BNE, Op.CMP, Op.NON, Op.NON, Op.NON, Op.CMP, Op.DEC, Op.NON, Op.CLD, Op.CMP, Op.NON, Op.NON, Op.NON, Op.CMP, Op.DEC, Op.NON,	//D
Op.CPX, Op.SBC, Op.NON, Op.NON, Op.CPX, Op.SBC, Op.INC, Op.NON, Op.INX, Op.SBC, Op.NOP, Op.NON, Op.CPX, Op.SBC, Op.INC, Op.NON,	//E
Op.BEQ, Op.SBC, Op.NON, Op.NON, Op.NON, Op.SBC, Op.INC, Op.NON, Op.SED, Op.SBC, Op.NON, Op.NON, Op.NON, Op.SBC, Op.INC, Op.NON	//F
];

//memory access mode for each opcode
const Mode[256] opcodeAddressingMode = [
//0       1         2         3         4         5         6         7         8         9         A         B         C         D         E         F
Mode.IMP, Mode.INX, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMM, Mode.ACC, Mode.IMP, Mode.IMP, Mode.ABS, Mode.ABS, Mode.IMP, //0
Mode.REL, Mode.INY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.IMP, Mode.ABY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ABX, Mode.ABX, Mode.IMP, //1
Mode.ABS, Mode.INX, Mode.IMP, Mode.IMP, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMM, Mode.ACC, Mode.IMP, Mode.ABS, Mode.ABS, Mode.ABS, Mode.IMP, //2
Mode.REL, Mode.INY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.IMP, Mode.ABY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ABX, Mode.ABX, Mode.IMP, //3
Mode.IMP, Mode.INX, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMM, Mode.ACC, Mode.IMP, Mode.ABS, Mode.ABS, Mode.ABS, Mode.IMP, //4
Mode.REL, Mode.INY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.IMP, Mode.ABY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ABX, Mode.ABX, Mode.IMP, //5
Mode.IMP, Mode.INX, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMM, Mode.ACC, Mode.IMP, Mode.IND, Mode.ABS, Mode.ABS, Mode.IMP, //6
Mode.REL, Mode.INY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.IMP, Mode.ABY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ABX, Mode.ABX, Mode.IMP, //7
Mode.IMP, Mode.INX, Mode.IMP, Mode.IMP, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ABS, Mode.ABS, Mode.ABS, Mode.IMP, //8
Mode.REL, Mode.INY, Mode.IMP, Mode.IMP, Mode.ZPX, Mode.ZPX, Mode.ZPY, Mode.IMP, Mode.IMP, Mode.ABY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ABX, Mode.IMP, Mode.IMP, //9
Mode.IMM, Mode.INX, Mode.IMM, Mode.IMP, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMM, Mode.IMP, Mode.IMP, Mode.ABS, Mode.ABS, Mode.ABS, Mode.IMP, //A
Mode.REL, Mode.INY, Mode.IMP, Mode.IMP, Mode.ZPX, Mode.ZPX, Mode.ZPY, Mode.IMP, Mode.IMP, Mode.ABY, Mode.IMP, Mode.IMP, Mode.ABX, Mode.ABX, Mode.ABY, Mode.IMP, //B
Mode.IMM, Mode.INX, Mode.IMP, Mode.IMP, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMM, Mode.IMP, Mode.IMP, Mode.ABS, Mode.ABS, Mode.ABS, Mode.IMP, //C
Mode.REL, Mode.INY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.IMP, Mode.ABY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ABX, Mode.ABX, Mode.IMP, //D
Mode.IMM, Mode.INX, Mode.IMP, Mode.IMP, Mode.ZPG, Mode.ZPG, Mode.ZPG, Mode.IMP, Mode.IMP, Mode.IMM, Mode.IMP, Mode.IMP, Mode.ABS, Mode.ABS, Mode.ABS, Mode.IMP, //E
Mode.REL, Mode.IMP, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ZPX, Mode.ZPX, Mode.IMP, Mode.IMP, Mode.ABY, Mode.IMP, Mode.IMP, Mode.IMP, Mode.ABX, Mode.ABX, Mode.IMP  //F
];

//base cycle costs for each opcode
const byte[256] cycleCosts = [
  //0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
	7, 6, 0, 0, 0, 3, 5, 0, 3, 2, 2, 0, 0, 4, 6, 0, //0
	2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, //1
	6, 6, 0, 0, 3, 3, 5, 0, 4, 2, 2, 0, 4, 4, 6, 0, //2
	2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, //3
	6, 6, 0, 0, 0, 3, 5, 0, 3, 2, 2, 0, 3, 4, 6, 0, //4
	2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, //5
	6, 6, 0, 0, 0, 3, 5, 0, 4, 2, 2, 0, 5, 4, 6, 0, //6
	2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, //7
	0, 6, 0, 0, 3, 3, 3, 0, 2, 0, 2, 0, 4, 4, 4, 0, //8
	2, 6, 0, 0, 4, 4, 4, 0, 2, 5, 2, 0, 0, 5, 0, 0, //9
	2, 6, 2, 0, 3, 3, 3, 0, 2, 2, 2, 0, 4, 4, 4, 0, //A
	2, 5, 0, 0, 4, 4, 4, 0, 2, 4, 2, 0, 4, 4, 4, 0, //B
	2, 6, 0, 0, 3, 3, 5, 0, 2, 2, 2, 0, 4, 4, 6, 0, //C
	2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, //D
	2, 6, 0, 0, 3, 3, 5, 0, 2, 2, 2, 0, 4, 4, 6, 0, //E
	2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0  //F
];

class Cpu {
	
	private void delegate(Mode, ubyte, ushort)[Op] operationDelegates;
	private CpuMemory memory;
	
	//registers
	private ushort pc; //program counter
	private ubyte sp; //stack pointer
	private ubyte a; //accumulator
	private ubyte x; //index register X
	private ubyte y; //index register Y
	private ubyte p; //flags: negative, overflow, none, break command, decimal mode, interrupts disabled, zero, carry
	
	private uint cycles = 0;
	
	private Interruption interruption = Interruption.NONE;
	private bool brkInterruption = false; //true if interruption caused by brk
	private static final ushort irqAddress = 0xFFFE;
	private static final ushort nmiAddress = 0xFFFA;
	private static final ushort resetAddress = 0xFFFC;
	
	private static final ubyte negativeFlagMask = 0B10000000;
	private static final ubyte overflowFlagMask = 0B01000000;
	private static final ubyte breakFlagMask = 0B00010000;
	private static final ubyte decimalFlagMask = 0B00001000; //not used
	private static final ubyte interruptsDisabledFlagMask = 0B00000100;
	private static final ubyte zeroFlagMask = 0B00000010;
	private static final ubyte carryFlagMask = 0B00000001;
	private static final ubyte signBitMask = 0b10000000;
	
	private static final ushort stackLocation = 0x0100;
	
	this() {
		operationDelegates = [
			Op.ADC:&adc, Op.AND:&and, Op.ASL:&asl, Op.BCC:&bcc, Op.BCS:&bcs, Op.BEQ:&beq, Op.BIT:&bit, Op.BMI:&bmi,
			Op.BNE:&bne, Op.BPL:&bpl, Op.BRK:&brk, Op.BVC:&bvc, Op.BVS:&bvs, Op.CLC:&clc, Op.CLD:&cld, Op.CLI:&cli,
			Op.CLV:&cli, Op.CMP:&cmp, Op.CPX:&cpx, Op.CPY:&cpy, Op.DEC:&dec, Op.DEX:&dex, Op.DEY:&dey, Op.EOR:&eor,
			Op.INC:&inc, Op.INX:&inx, Op.INY:&iny, Op.JMP:&jmp, Op.JSR:&jsr, Op.LDA:&lda, Op.LDX:&ldx, Op.LDY:&ldy,
			Op.LSR:&lsr, Op.NOP:&nop, Op.ORA:&ora, Op.PHA:&pha, Op.PHP:&php, Op.PLA:&pla, Op.PLP:&plp, Op.ROL:&rol,
			Op.ROR:&ror, Op.RTI:&rti, Op.RTS:&rts, Op.SBC:&sbc, Op.SEC:&sec, Op.SED:&sed, Op.SEI:&sei, Op.STA:&sta,
			Op.STX:&stx, Op.STY:&sty, Op.TAX:&tax, Op.TAY:&tay, Op.TSX:&tsx, Op.TXA:&txa, Op.TXS:&txs, Op.TYA:&tya
		];
	}
	
	public void cycle() {
		
	}
	
	public void executeInstruction(uint instruction) {
		ubyte opcode = cast(ubyte) (instruction >> 24); //first byte
		ubyte immediate = cast(ubyte) (instruction >> 16); //second byte, immediate value or zpg address or sumtthing
		ushort address = cast(ushort) (instruction >> 8); //second and third byte, usually address
		Op operation = opcodeOperation[opcode];
		Mode mode = opcodeAddressingMode[opcode];
		
		if(interruption != Interruption.NONE) jumpToInterruptionHandler();
		else {
			executeOpcode(operation, mode, immediate, address);
			addPC(getInstructionSize(operation, mode));
			addCycles(getCycleCost(opcode) + memory.getPageCrossedValue());
			memory.clearPageCrossed();
		}
	}
	
	public void executeOpcode(Op operation, Mode addressingMode, ubyte immediate, ushort address) {
		operationDelegates[operation](addressingMode, immediate, address);
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
		updateCarryFlag(result);
		updateZeroFlag(result);
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
		int result = getA();
		result <<= 1;
		setA(result);
		updateCarryFlag(result);
		updateZeroFlag(result);
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
		setOverflowFlag(cast(bool) (result & overflowFlagMask));
		updateNegativeFlag(result);
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
		assert(false, "clear decimal mode (cld) instruction not implemented");
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
		updateNegativeFlag(value);
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
		updateNegativeFlag(value);
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
		updateNegativeFlag(value);
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
	
	/*
	Jump
	Sets the program counter to the address specified by the operand.
	*/
	public void jmp(Mode mode, ubyte immediate, ushort address) {
		if(mode == Mode.ABS) setPC(address);
		else if(mode == Mode.IND) {
			ushort realAddress = memory.read(address);
			realAddress += memory.read(address + 1) << 8;
			setPC(realAddress);
		}
	}
	
	/*
	Jump to Subroutine
	The JSR instruction pushes the address (minus one) of the return point on to the stack and then sets the program
	counter to the target memory address.
	*/
	public void jsr(Mode mode, ubyte immediate, ushort address) {
		setPC(address);
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
		pushStack(getP());
	}
	/*
	Pull Accumulator
	Pulls an 8 bit value from the stack and into the accumulator. The zero and negative flags are set as appropriate.
	*/
	public void pla(Mode mode, ubyte immediate, ushort address) {
		setA(popStack());
	}
	
	/*
	Pull Processor Status
	Pulls an 8 bit value from the stack and into the processor flags. The flags will take on new states as determined
	by the value pulled.
	*/
	public void plp(Mode mode, ubyte immediate, ushort address) {
		setP(popStack());
	}
	
	/*
	Rotate Left
	Move each of the bits in either A or M one place to the left. Bit 0 is filled with the current value of the carry
	flag whilst the old bit 7 becomes the new carry flag value.
	*/
	public void rol(Mode mode, ubyte immediate, ushort address) {
		ubyte value = memory.read(mode, immediate, address);
		setCarryFlag(cast(bool) (value & 0b10000000));
		value <<= 1;
		value = cast(ubyte) ((value & 0b11111110) + getCarryFlagValue());
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
		setCarryFlag(cast(bool) (value & 0b00000001));
		value >>= 1;
		value = cast(ubyte) ((value & 0b01111111) + (getCarryFlagValue() << 7));
		memory.write(mode, immediate, address, value);
		updateZeroFlag(value);
		updateNegativeFlag(value);
	}
	
	/*
	Return from Interrupt
	The RTI instruction is used at the end of an interrupt processing routine. It pulls the processor flags from the
	stack followed by the program counter.
	*/
	public void rti(Mode mode, ubyte immediate, ushort address) {
		setP(popStack());
		setPC(popStack16());
	}
	
	/*
	Return from Subroutine
	The RTS instruction is used at the end of a subroutine to return to the calling routine. It pulls the program
	counter (minus one) from the stack.
	*/
	public void rts(Mode mode, ubyte immediate, ushort address) {
		setPC(popStack);
	}
	
	/*
	Subtract with Carry
	This instruction subtracts the contents of a memory location to the accumulator together with the not of the carry
	bit. If overflow occurs the carry bit is clear, this enables multiple byte subtraction to be performed.
	*/
	public void sbc(Mode mode, ubyte immediate, ushort address) {
		int value = memory.read(mode, immediate, address);
		uint result = getA() - value - (~getCarryFlagValue() & carryFlagMask);
		updateOverflowFlag(getA(), value, result);
		setA(result);
		setCarryFlag(!getOverflowFlag()); //???
		updateZeroFlag(result);
		updateNegativeFlag(result);
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
		assert(false, "decimal stuff not implemented");
	}
	
	/*
	Set Interrupt Disable
	Set the interrupt disable flag to one.
	*/
	public void sei(Mode mode, ubyte immediate, ushort address) {
		setInterruptsDisabledFlag(true);
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
		return cast(bool) p & carryFlagMask;
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
		if(zero) p = cast(ubyte) ((p & ~zeroFlagMask) + zeroFlagMask);
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
		if(overflow) p = cast(ubyte) ((p & (~overflowFlagMask)) + overflowFlagMask);
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
	
	public void stall(int cycles) {
		assert(false, "TODO stealCycles");
	}
	
	public void raiseInterruption(Interruption interrupion) {
		if(interruption > this.interruption) {
			if(interruption == Interruption.IRQ && !getInterruptsDisabledFlag()) {
				this.interruption = interruption;
			}
			else if(interruption != Interruption.IRQ) this.interruption = interruption;
		}
	}
	
	private void jumpToInterruptionHandler() {
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
	
	private int getInstructionSize(Op operation, Mode mode) {
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
		else if(mode == Mode.ZPG) return 1;
		else if(mode == Mode.ZPX) return 1;
		else if(mode == Mode.ZPY) return 1;
		else assert(false, "hölöködöö");
	}
	
	private void addCycles(int amount) {
		this.cycles += amount;
	}
	
	private byte getCycleCost(ubyte opcode) {
		return cycleCosts[opcode];
	}
	
	private void pushStack(ubyte value) {
		memory.write(stackLocation + getSP(), value);
		setSP(getSP() - 1);
	}
	
	private void pushStack(ushort value) {
		pushStack(cast(ubyte) value);
		pushStack(cast(ubyte) (value << 8));
	}
	
	private ubyte popStack() {
		setSP(getSP() + 1);
		return memory.read(stackLocation + getSP() - 1);
	}
	
	private ushort popStack16() {
		ushort value = popStack();
		value <<= 8;
		value += popStack();
		return value;
	}

}





















