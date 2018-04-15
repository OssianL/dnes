module dnes.cpu;

import dnes;
import std.stdio;
import std.conv;
import std.format;

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
//0     1       2       3       4       5       6       7       8       9       A       B       C       D       E       F
Op.BRK, Op.ORA, Op.NOP, Op.SLO, Op.NOP, Op.ORA, Op.ASL, Op.SLO, Op.PHP, Op.ORA, Op.ASL, Op.NOP, Op.NOP, Op.ORA, Op.ASL, Op.SLO, //0
Op.BPL, Op.ORA, Op.NOP, Op.SLO, Op.NOP, Op.ORA, Op.ASL, Op.SLO, Op.CLC, Op.ORA, Op.NOP, Op.SLO, Op.NOP, Op.ORA, Op.ASL, Op.SLO, //1
Op.JSR, Op.AND, Op.NOP, Op.RLA, Op.BIT, Op.AND, Op.ROL, Op.RLA, Op.PLP, Op.AND, Op.ROL, Op.NOP, Op.BIT, Op.AND, Op.ROL, Op.RLA, //2
Op.BMI, Op.AND, Op.NOP, Op.RLA, Op.NOP, Op.AND, Op.ROL, Op.RLA, Op.SEC, Op.AND, Op.NOP, Op.RLA, Op.NOP, Op.AND, Op.ROL, Op.RLA, //3
Op.RTI, Op.EOR, Op.NOP, Op.SRE, Op.NOP, Op.EOR, Op.LSR, Op.SRE, Op.PHA, Op.EOR, Op.LSR, Op.NOP, Op.JMP, Op.EOR, Op.LSR, Op.SRE, //4
Op.BVC, Op.EOR, Op.NOP, Op.SRE, Op.NOP, Op.EOR, Op.LSR, Op.SRE, Op.CLI, Op.EOR, Op.NOP, Op.SRE, Op.NOP, Op.EOR, Op.LSR, Op.SRE, //5
Op.RTS, Op.ADC, Op.NOP, Op.RRA, Op.NOP, Op.ADC, Op.ROR, Op.RRA, Op.PLA, Op.ADC, Op.ROR, Op.NOP, Op.JMP, Op.ADC, Op.ROR, Op.RRA, //6
Op.BVS, Op.ADC, Op.NOP, Op.RRA, Op.NOP, Op.ADC, Op.ROR, Op.RRA, Op.SEI, Op.ADC, Op.NOP, Op.RRA, Op.NOP, Op.ADC, Op.ROR, Op.RRA, //7
Op.NOP, Op.STA, Op.NOP, Op.SAX, Op.STY, Op.STA, Op.STX, Op.SAX, Op.DEY, Op.NOP, Op.TXA, Op.NOP, Op.STY, Op.STA, Op.STX, Op.SAX, //8
Op.BCC, Op.STA, Op.NOP, Op.NOP, Op.STY, Op.STA, Op.STX, Op.SAX, Op.TYA, Op.STA, Op.TXS, Op.NOP, Op.NOP, Op.STA, Op.NOP, Op.NOP, //9
Op.LDY, Op.LDA, Op.LDX, Op.LAX, Op.LDY, Op.LDA, Op.LDX, Op.LAX, Op.TAY, Op.LDA, Op.TAX, Op.LAX, Op.LDY, Op.LDA, Op.LDX, Op.LAX, //A
Op.BCS, Op.LDA, Op.NOP, Op.LAX, Op.LDY, Op.LDA, Op.LDX, Op.LAX, Op.CLV, Op.LDA, Op.TSX, Op.NOP, Op.LDY, Op.LDA, Op.LDX, Op.LAX, //B
Op.CPY, Op.CMP, Op.NOP, Op.DCP, Op.CPY, Op.CMP, Op.DEC, Op.DCP, Op.INY, Op.CMP, Op.DEX, Op.NOP, Op.CPY, Op.CMP, Op.DEC, Op.DCP, //C
Op.BNE, Op.CMP, Op.NOP, Op.DCP, Op.NOP, Op.CMP, Op.DEC, Op.DCP, Op.CLD, Op.CMP, Op.NOP, Op.DCP, Op.NOP, Op.CMP, Op.DEC, Op.DCP, //D
Op.CPX, Op.SBC, Op.NOP, Op.ISC, Op.CPX, Op.SBC, Op.INC, Op.ISC, Op.INX, Op.SBC, Op.NOP, Op.SBC, Op.CPX, Op.SBC, Op.INC, Op.ISC, //E
Op.BEQ, Op.SBC, Op.NOP, Op.ISC, Op.NOP, Op.SBC, Op.INC, Op.ISC, Op.SED, Op.SBC, Op.NOP, Op.ISC, Op.NOP, Op.SBC, Op.INC, Op.ISC  //F
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
    private void delegate()[256] operationDelegates;
    private CpuMemory memory;
    
    //registers
    private ushort pc; //program counter
    private ubyte sp; //stack pointer
    private ubyte a; //accumulator
    private ubyte x; //index register X
    private ubyte y; //index register Y
    //status register
    private bool negativeFlag;
    private bool overflowFlag;
    private bool unusedFlag;
    private bool breakFlag;
    private bool decimalModeFlag;
    private bool interruptsDisabledFlag;
    private bool zeroFlag;
    private bool carryFlag;
    enum negativeFlagMask = 0B10000000;
    enum overflowFlagMask = 0B01000000;
    enum unusedFlagMask = 0B00100000;
    enum breakFlagMask = 0B00010000;
    enum decimalModeFlagMask = 0B00001000; //can be set but is ignored
    enum interruptsDisabledFlagMask = 0B00000100;
    enum zeroFlagMask = 0B00000010;
    enum carryFlagMask = 0B00000001;
    enum signBitMask = 0b10000000;
    
    private ubyte opcode;
    private ubyte immediate;
    private ushort address;
    private Op operation;
    private Mode mode;
    private uint cycles;
    private uint stallCycles; //cycles to stall (kind of already used cycles)
    private uint instructions;
    
    private Interruption interruption = Interruption.NONE;
    private bool brkInterruption = false; //true if interruption caused by brk
    enum irqAddress = 0xFFFE;
    enum nmiAddress = 0xFFFA;
    enum resetAddress = 0xFFFC;
    
    enum stackAddress = 0x0100;
    
    this(Nes nes) {
        this.nes = nes;
        this.memory = new CpuMemory(nes);
        operationDelegates = [
        //0   1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
        &brk, &ora, &nop, &slo, &nop, &ora, &asl, &slo, &php, &ora, &asl, &nop, &nop, &ora, &asl, &slo, //0
        &bpl, &ora, &nop, &slo, &nop, &ora, &asl, &slo, &clc, &ora, &nop, &slo, &nop, &ora, &asl, &slo, //1
        &jsr, &and, &nop, &rla, &bit, &and, &rol, &rla, &plp, &and, &rol, &nop, &bit, &and, &rol, &rla, //2
        &bmi, &and, &nop, &rla, &nop, &and, &rol, &rla, &sec, &and, &nop, &rla, &nop, &and, &rol, &rla, //3
        &rti, &eor, &nop, &sre, &nop, &eor, &lsr, &sre, &pha, &eor, &lsr, &nop, &jmp, &eor, &lsr, &sre, //4
        &bvc, &eor, &nop, &sre, &nop, &eor, &lsr, &sre, &cli, &eor, &nop, &sre, &nop, &eor, &lsr, &sre, //5
        &rts, &adc, &nop, &rra, &nop, &adc, &ror, &rra, &pla, &adc, &ror, &nop, &jmp, &adc, &ror, &rra, //6
        &bvs, &adc, &nop, &rra, &nop, &adc, &ror, &rra, &sei, &adc, &nop, &rra, &nop, &adc, &ror, &rra, //7
        &nop, &sta, &nop, &sax, &sty, &sta, &stx, &sax, &dey, &nop, &txa, &nop, &sty, &sta, &stx, &sax, //8
        &bcc, &sta, &nop, &nop, &sty, &sta, &stx, &sax, &tya, &sta, &txs, &nop, &nop, &sta, &nop, &nop, //9
        &ldy, &lda, &ldx, &lax, &ldy, &lda, &ldx, &lax, &tay, &lda, &tax, &lax, &ldy, &lda, &ldx, &lax, //a
        &bcs, &lda, &nop, &lax, &ldy, &lda, &ldx, &lax, &clv, &lda, &tsx, &nop, &ldy, &lda, &ldx, &lax, //b
        &cpy, &cmp, &nop, &dcp, &cpy, &cmp, &dec, &dcp, &iny, &cmp, &dex, &nop, &cpy, &cmp, &dec, &dcp, //c
        &bne, &cmp, &nop, &dcp, &nop, &cmp, &dec, &dcp, &cld, &cmp, &nop, &dcp, &nop, &cmp, &dec, &dcp, //d
        &cpx, &sbc, &nop, &isc, &cpx, &sbc, &inc, &isc, &inx, &sbc, &nop, &sbc, &cpx, &sbc, &inc, &isc, //e
        &beq, &sbc, &nop, &isc, &nop, &sbc, &inc, &isc, &sed, &sbc, &nop, &isc, &nop, &sbc, &inc, &isc  //f
        ];
    }
    
    public void powerUp() {
        writeln("cpu power up");
        setP(cast(ubyte) 0x24); //documentation says 0x36 but nintendulator seems to use 0x24
        setA(0);
        setX(0);
        setY(0);
        setSP(0xfd);
        setPC(memory.read16(resetAddress));
        loadNextInstruction();
    }
    
    public void reset() {
        writeln("cpu reset");
        setSP(getSP() - 3);
        setInterruptsDisabledFlag(true);
        raiseInterruption(Interruption.RESET);
    }
    
    public void step() {
        executeInstruction();
        if(!isStalling()) loadNextInstruction();
    }
    
    public void loadNextInstruction() {
        opcode = memory.read(pc); //first byte
        immediate = memory.read(pc + 1); //second byte, immediate value or zpg address
        address = memory.read16(pc + 1); //second and third byte, usually address
        operation = opcodeOperation[opcode];
        mode = opcodeAddressingMode[opcode];
    }
    
    private void executeInstruction() {
        if(isStalling()) stall();
        else if(interruption != Interruption.NONE) jumpToInterruptionHandler();
        else {
            //printDebugLine();
            instructions++;
            addPC(getInstructionSize(mode));
            operationDelegates[opcode]();
            addStallCycles(getCycleCost(opcode) + memory.getPageCrossedValue());
            memory.clearPageCrossed();
        }
        cycles++;
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
        ubyte p;
        if(negativeFlag) p |= negativeFlagMask;
        if(overflowFlag) p |= overflowFlagMask;
        if(unusedFlag) p |= unusedFlagMask;
        if(breakFlag) p |= breakFlagMask;
        if(decimalModeFlag) p |= decimalModeFlagMask;
        if(interruptsDisabledFlag) p |= interruptsDisabledFlagMask;
        if(zeroFlag) p |= zeroFlagMask;
        if(carryFlag) p |= carryFlagMask;
        return p;
    }
    
    public void setP(ubyte p) {
        setNegativeFlag(cast(bool) (p & negativeFlagMask));
        setOverflowFlag(cast(bool) (p & overflowFlagMask));
        setUnusedFlag(cast(bool) (p & unusedFlagMask));
        setBreakFlag(cast(bool) (p & breakFlagMask));
        setDecimalModeFlag(cast(bool) (p & decimalModeFlagMask));
        setInterruptsDisabledFlag(cast(bool) (p & interruptsDisabledFlagMask));
        setZeroFlag(cast(bool) (p & zeroFlagMask));
        setCarryFlag(cast(bool) (p & carryFlagMask));
    }
    
    public bool getNegativeFlag() {
        return negativeFlag;
    }
    
    public void setNegativeFlag(bool negativeFlag) {
        this.negativeFlag = negativeFlag;
    }
    
    public void updateNegativeFlag(int value) {
        if(value & signBitMask) setNegativeFlag(true);
        else setNegativeFlag(false);
    }
    
    public bool getOverflowFlag() {
        return overflowFlag;
    }
    
    public void setOverflowFlag(bool overflowFlag) {
        this.overflowFlag = overflowFlag;
    }
    
    public void updateOverflowFlag(uint value1, uint value2, uint result) {
        setOverflowFlag(cast(bool) ((value1 ^ result) & (value2 ^ result) & signBitMask));
    }
    
    public bool getUnusedFlag() {
        return unusedFlag;
    }
    
    public void setUnusedFlag(bool unusedFlag) {
        this.unusedFlag = unusedFlag;
    }
    
    public void setBreakFlag(bool breakFlag) {
        this.breakFlag = breakFlag;
    }
    
    public bool getBreakCommandFlag() {
        return breakFlag;
    }
    
    public bool getDecimalModeFlag() {
        return decimalModeFlag;
    }
    
    public void setDecimalModeFlag(bool decimalModeFlag) {
        this.decimalModeFlag = decimalModeFlag;
    }
    
    public bool getInterruptsDisabledFlag() {
        return interruptsDisabledFlag;
    }
    
    public void setInterruptsDisabledFlag(bool interruptsDisabledFlag) {
        this.interruptsDisabledFlag = interruptsDisabledFlag;
    }
    
    public bool getZeroFlag() {
        return zeroFlag;
    }
    
    public void setZeroFlag(bool zeroFlag) {
        this.zeroFlag = zeroFlag;
    }
    
    public void updateZeroFlag(int zero) {
        if(zero == 0) setZeroFlag(true);
        else setZeroFlag(false);
    }
    
    public bool getCarryFlag() {
        return carryFlag;
    }
    
    public ubyte getCarryFlagValue() {
        if(carryFlag) return 1;
        else return 0;
    }
    
    public void setCarryFlag(bool carryFlag) {
        this.carryFlag = carryFlag;
    }
    
    public void updateCarryFlag(int number) {
        if(number > 0xFF) setCarryFlag(true);
        else setCarryFlag(false);
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
    
    public void raiseInterruption(Interruption newInterruption) {
        if(newInterruption > this.interruption) {
            if(newInterruption == Interruption.IRQ && !getInterruptsDisabledFlag()) {
                this.interruption = newInterruption;
            }
            else if(newInterruption != Interruption.IRQ) this.interruption = newInterruption;
        }
    }
    
    public CpuMemory getMemory() {
        return memory;
    }

    public void addStallCycles(int stallCycles) {
        this.stallCycles += stallCycles;
    }
    
    public bool isStalling() {
        return stallCycles > 0;
    }
    
    private void stall() {
        if(stallCycles <= 0) return;
        stallCycles--;
    }
    
    private void printDebugLine() {
        if(getInstructions() % 10 == 0) writeln("\n\tcycles\top\tmode\tint\topcode\timm\taddr\tpc\tsp\ta\tx\ty\tp");
        string newDebugLine = to!string(getInstructions() + 1) ~ ": \t" ~ to!string(getCycles());
        newDebugLine ~= "\t" ~ to!string(getOperation()) ~ "\t" ~ to!string(getMode()) ~ "\t" ~ to!string(getInterruption());
        newDebugLine ~= format!"\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x"(getOpcode(), getImmediate(), getAddress(), getPC(), getSP(), getA(), getX(), getY(), getP());
        writeln(newDebugLine);
    }
    
    /*
    Add with Carry
    This instruction adds the contents of a memory location to the accumulator together with the carry bit.
    If overflow occurs the carry bit is set, this enables multiple byte addition to be performed.
    */
    private void adc() {
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
    private void and() {
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
    private void asl() {
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
    private void bcc() {
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
    private void bcs() {
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
    private void beq() {
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
    private void bit() {
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
    private void bmi() {
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
    private void bne() {
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
    private void bpl() {
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
    private void brk() {
        raiseInterruption(Interruption.IRQ);
        brkInterruption = true;
    }
    
    /*
    Branch if Overflow Clear
    If the overflow flag is clear then add the relative displacement to the program counter to cause a branch to a new
    location.
    */
    private void bvc() {
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
    private void bvs() {
        if(getOverflowFlag()) {
            byte relativeAddress = cast(byte) immediate;
            branch(relativeAddress);
        }
    }
    
    /*
    Clear Carry Flag
    Set the carry flag to zero.
    */
    private void clc() {
        setCarryFlag(false);
    }
    
    /*
    Clear Decimal Mode
    Not used in nes.
    */
    private void cld() {
        setDecimalModeFlag(false);
    }
    
    /*
    Clear Interrupt Disable
    Clears the interrupt disable flag allowing normal interrupt requests to be serviced.
    */
    private void cli() {
        setInterruptsDisabledFlag(false);
    }
    
    /*
    Clear Overflow Flag
    Clears the overflow flag.
    */
    private void clv() {
        setOverflowFlag(false);
    }
    
    /*
    Compare
    This instruction compares the contents of the accumulator with another memory held value and sets the zero and
    carry flags as appropriate.
    */
    private void cmp() {
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
    private void cpx() {
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
    private void cpy() {
        ubyte value = memory.read(mode, immediate, address);
        setCarryFlag(getY() >= value);
        setZeroFlag(getY() == value);
        updateNegativeFlag(cast(ubyte) (getY() - value));
    }
    
    /* UNOFFICIAL
    Equivalent to DEC value then CMP value, except supporting more addressing modes. LDA #$FF followed by DCP can be
    used to check if the decrement underflows, which is useful for multi-byte decrements.
    */
    private void dcp() {
        dec();
        cmp();
    }
    
    /*
    Decrement Memory
    Subtracts one from the value held at a specified memory location setting the zero and negative flags as appropriate.
    */
    private void dec() {
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
    private void dex() {
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
    private void dey() {
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
    private void eor() {
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
    private void inc() {
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
    private void inx() {
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
    private void iny() {
        ubyte value = getY();
        value++;
        setY(value);
        updateZeroFlag(value);
        updateNegativeFlag(value);
    }
    
    /* UNOFFICIAL
    Equivalent to INC value then SBC value, except supporting more addressing modes.
    */
    private void isc() {
        inc();
        sbc();
        setOverflowFlag(false); //nestest expects this. don't know why, no documentation.
    }
    
    /*
    Jump
    Sets the program counter to the address specified by the operand.
    */
    private void jmp() {
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
    private void jsr() {
        pushStack(cast(ushort) (getPC() - 1));
        setPC(address);
    }
    
    /*UNOFFICIAL
    Combined lda tax
    Shortcut for LDA value then TAX. Saves a byte and two cycles and allows use of the X register with the
    (d),Y addressing mode. Notice that the immediate is missing; the opcode that would have been LAX is affected by
    line noise on the data bus. MOS 6502: even the bugs have bugs.
    */
    private void lax() {
        lda();
        tax();
    }
    
    /*
    Load Accumulator
    Loads a byte of memory into the accumulator setting the zero and negative flags as appropriate.
    */
    private void lda() {
        ubyte value = memory.read(mode, immediate, address);
        setA(value);
        updateZeroFlag(value);
        updateNegativeFlag(value);
    }
    
    /*
    Load X Register
    Loads a byte of memory into the X register setting the zero and negative flags as appropriate.
    */
    private void ldx() {
        ubyte value = memory.read(mode, immediate, address);
        setX(value);
        updateZeroFlag(value);
        updateNegativeFlag(value); 
    }
    
    /*
    Load Y Register
    Loads a byte of memory into the Y register setting the zero and negative flags as appropriate.
    */
    private void ldy() {
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
    private void lsr() {
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
    private void nop() {
        
    }
    
    /*
    Logical Inclusive OR
    An inclusive OR is performed, bit by bit, on the accumulator contents using the contents of a byte of memory.
    */
    private void ora() {
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
    private void pha() {
        pushStack(getA());
    }
    
    /*
    Push Processor Status
    Pushes a copy of the status flags on to the stack.
    */
    private void php() {
        ubyte pushP = getP();
        pushP |= 0b00100000; //bit 5 always set
        pushP |= 0b00010000; //bit 4 set for brk and php
        pushStack(pushP);
    }
    /*
    Pull Accumulator
    Pulls an 8 bit value from the stack and into the accumulator. The zero and negative flags are set as appropriate.
    */
    private void pla() {
        setA(popStack());
        updateZeroFlag(getA());
        updateNegativeFlag(getA());
    }
    
    /*
    Pull Processor Status
    Pulls an 8 bit value from the stack and into the processor flags. The flags will take on new states as determined
    by the value pulled. break flag will be ignored
    */
    private void plp() {
        ubyte newP = popStack() & ~(breakFlagMask); //ignore break flag
        newP |= 0b00100000; //nestest requires bit 5 to be set when loading
        setP((getP() & breakFlagMask) | newP); //keep old break flag(?)
    }
    
    
    /* UNOFFICIAL
    Equivalent to ROL value then AND value, except supporting more addressing modes.
    LDA #$FF followed by RLA is an efficient way to rotate a variable while also loading it in A.
    */
    private void rla() {
        rol();
        and();
    }
    
    /*
    Rotate Left
    Move each of the bits in either A or M one place to the left. Bit 0 is filled with the current value of the carry
    flag whilst the old bit 7 becomes the new carry flag value.
    */
    private void rol() {
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
    private void ror() {
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
    private void rra() {
        ror();
        adc();
    }
    
    /*
    Return from Interrupt
    The RTI instruction is used at the end of an interrupt processing routine. It pulls the processor flags (except break flag) from the
    stack followed by the program counter.
    */
    private void rti() {
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
    private void rts() {
        setPC(popStack16() + 1);
    }
    
    /* UNOFFICIAL
    Stores the bitwise AND of A and X. As with STA and STX, no flags are affected.
    */
    private void sax() {
        memory.write(mode, immediate, address, getA() & getX());
    }
    
    /*
    Subtract with Carry
    This instruction subtracts the contents of a memory location to the accumulator together with the not of the carry
    bit. If overflow occurs the carry bit is clear, this enables multiple byte subtraction to be performed.
    */
    private void sbc() {
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
    private void sec() {
        setCarryFlag(true);
    }
    
    /*
    Set Decimal Flag
    Set the decimal mode flag to one.
    */
    private void sed() {
        setDecimalModeFlag(true);
    }
    
    /*
    Set Interrupt Disable
    Set the interrupt disable flag to one.
    */
    private void sei() {
        setInterruptsDisabledFlag(true);
    }
    
    /* UNOFFICIAL
    Equivalent to ASL value then ORA value, except supporting more addressing modes. LDA #0 followed by SLO is an
    efficient way to shift a variable while also loading it in A.
    */
    private void slo() {
        asl();
        ora();
    }
    
    /* UNOFFICIAL
    Equivalent to LSR value then EOR value, except supporting more addressing modes. LDA #0 followed by SRE is an
    efficient way to shift a variable while also loading it in A.
    */
    private void sre() {
        lsr();
        eor();
    }
    
    /*
    Store Accumulator
    Stores the contents of the accumulator into memory.
    */
    private void sta() {
        memory.write(mode, immediate, address, getA());
    }
    
    /*
    Store X Register
    Stores the contents of the X register into memory.
    */
    private void stx() {
        memory.write(mode, immediate, address, getX());
    }
    
    /*
    Store Y Register
    Stores the contents of the Y register into memory.
    */
    private void sty() {
        memory.write(mode, immediate, address, getY());
    }
    
    /*
    Transfer Accumulator to X
    Copies the current contents of the accumulator into the X register and sets the zero and negative flags as
    appropriate.
    */
    private void tax() {
        setX(getA());
        updateZeroFlag(getX());
        updateNegativeFlag(getX());
    }
    
    /*
    Transfer Accumulator to Y
    Copies the current contents of the accumulator into the Y register and sets the zero and negative flags as
    appropriate.
    */
    private void tay() {
        setY(getA());
        updateZeroFlag(getY());
        updateNegativeFlag(getY());
    }
    
    /*
    Transfer Stack Pointer to X
    Copies the current contents of the stack register into the X register and sets the zero and negative flags as
    appropriate.
    */
    private void tsx() {
        setX(getSP());
        updateZeroFlag(getX());
        updateNegativeFlag(getX());
    }
    
    /*
    Transfer X to Accumulator
    Copies the current contents of the X register into the accumulator and sets the zero and negative flags as
    appropriate.
    */
    private void txa() {
        setA(getX());
        updateZeroFlag(getA());
        updateNegativeFlag(getA());
    }
    
    /*
    Transfer X to Stack Pointer
    Copies the current contents of the X register into the stack register.
    */
    private void txs() {
        setSP(getX());
    }
    
    /*
    Transfer Y to Accumulator
    Copies the current contents of the Y register into the accumulator and sets the zero and negative flags as
    appropriate.
    */
    private void tya() {
        setA(getY());
        updateZeroFlag(getA());
        updateNegativeFlag(getA());
    }
    
    
    private void jumpToInterruptionHandler() {
        pushStack(getPC());
        pushStack(getP());
        if(brkInterruption) setBreakFlag(true);
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
        return value;
    }
    
    private ushort popStack16() {
        ushort value = popStack();
        value |= cast(ushort) (popStack()) << 8;
        return value;
    }

}

