module main

import scan

pub fn main() {

	cfg := scan.Cfg{
		name: 'vcan0'
	}
	socket := scan.new_socket(cfg) or {
		panic('new ${err}')
	}

	id := u32(0x12345678)
	data := [ u8(1), 2, 3, 4, 5, 6, 7, 8 ]
	can := scan.new_can(id, data) or {
		panic('can ${err}')
	}
	can_id := can.get_id()
	payload := can.get_data().bytes
	write := socket.write_29(can_id, payload) or {
		panic('write error: ${err}')
	}
	println('write: ${write}')
}
