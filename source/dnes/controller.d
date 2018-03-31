module dnes.controller;

import dnes;

class Controller {

	static enum Button {
		a, b, select, start, up, down, left, right
	}

	private bool[8] buttonStates;
	private bool strobe;
	private uint currentButton; //next button read
	
	this() {
	
	}
	
	public void write(ubyte value) {
		if((value & 1) == 1) {
			strobe = true;
			currentButton = 0;
		}
		else strobe = false;
	}
	
	public ubyte read() {
		ubyte value;
		if(currentButton >= 8) value = 0;
		else if(buttonStates[currentButton]) value = 1;
		if(!strobe) currentButton++;
		return value;
	}

	public void buttonDown(Button button) {
		buttonStates[button] = true;
	}

	public void buttonUp(Button button) {
		buttonStates[button] = false;
	}

}
