
interface Mapper {
	public ubyte cpuRead(ushort address);
	public void cpuWrite(ushort address, ubyte value);
	public ubyte chrRead(ushort address);
	public void chrWrite(ushort address, ubyte value);
	public bool useChrRom(ushort address); //return true if should use chrRom for given address
}
