module main

import encoding.hex
import flag
import os
import strconv

import scan

pub fn main() {
	sender := new_sender() or {
		panic('Arguments error: ${err}')
	}
	cfg := scan.Cfg{
		name: sender.iname
	}
	can := scan.new_can(sender.id, sender.data) or {
		panic('new_can error: ${err}')
	}
	can_id := can.get_id()
	payload := can.get_data().bytes

	socket := scan.new_socket(cfg) or {
		panic('new socket error: ${err}')
	}
	_ := socket.write_29(can_id, payload) or {
		panic('sender error: ${err}')
	}
	println(can.str())
	socket.close()
}

struct Sender {
	iname string
	id    u32
	data  []u8
}

fn new_sender() ! &Sender {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('scan_sender')
	fp.version('0.0.20250724')
	fp.description('Socket CAN sender')
	fp.skip_executable()

	d_interface := 'vcan0'
	d_message   := '12345678#01020304050607'

	iname   := fp.string('interface', `i`, '${d_interface}', 'The name of the interface, default(${d_interface})')
	message := fp.string('message', `m`, '${d_message}', 'Message in hex format id#payload, default(${d_message})')
	additional := fp.finalize()!
	if additional.len > 0 {
		return error('unprocessed args ${additional.join_lines()}')
	}
	id_data := message.split('#')
	if id_data.len != 2 {
		return error('Invalid message format: ${message}')
	}

	ids := id_data[0]
	id := strconv.parse_uint(ids, 16, 32) or {
		return error('Invalid message id format: ${ids}')
	}
	if id > 0x1f_ff_ff_ff {
		return error('Invalid message id length > 0x1fffffff: ${ids}')
	}
	dd := id_data[1]
	data := hex.decode(dd) or {
		return error('Invalid message data format: ${dd}')
	}
	if data.len > 8 {
		return error('Invalid message data length > 8: ${dd}')
	}
	return &Sender {
		iname: iname
		id:   u32(id) // default u32(0x12345678)
		data: data    // default [ u8(1), 2, 3, 4, 5, 6, 7, 8 ]
	}
}
