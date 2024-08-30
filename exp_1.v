module main 

import serial

fn main() {
	mut p1 := serial.new_port('/dev/ttyUSB0') or {
		println('${err}')
		return
	}

	p1.set_baudrate(115_200)
	p1.set_bits(8)
	p1.set_parity(serial.Parity.@none)
	p1.set_stopbits(1)
	p1.set_flowcontrol(serial.FlowControl.@none)
	p1.set_xon_xoff(serial.XonXoff.disabled)
	p1.set_rts(serial.Rts.off)
	p1.set_cts(serial.Cts.ignore)
	p1.set_dtr(serial.Dtr.off)
	p1.set_dsr(serial.Dsr.ignore)
	
	match p1.transport() {
		.native {
			println('Transport type: native.')
		}
		.usb {
			println('Transport type: usb')
			
			p1_desc := p1.description()
			ub := p1.usb_bus().str()
			ud := p1.usb_id().str()
			
			println('Desc:    ${p1_desc}')
			println('USB Bus: ${ub}')
			println('USB ID:  ${ud}')
		}
		.bluetooth {
			println('Trasport type: bluetooth')
		}
	}


	p1.set_baudrate(115_200)
	p1.set_parity(serial.Parity.@none)
	p1.set_bits(8)
	p1.set_stopbits(1)

	if p1.open(serial.Mode.read_write) == true {
		println('Port is open')
		p1.close()
	}

	code := serial.error_code()
	msg  := serial.error_message()
	println('>> [${code}]: ${msg}')


	p1.free()
}

