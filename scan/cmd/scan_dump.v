module main

import flag
import os
import time

import scan

fn main() {
	dumper := new_dumper() or {
		panic('Arguments error: ${err}')
	}
	cfg := scan.Cfg{
		name: dumper.iname
	}
	socket := scan.new_socket(cfg) or {
		panic('new socket error: ${err}')
	}
	println('scan_dump @ ${cfg.name}')
	socket.read_29(dumper.callback)! // blocks here
	socket.close()
}

struct Dumper {
	iname string
}

fn new_dumper() ! &Dumper {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('scan_dump')
	fp.version('0.0.20250724')
	fp.description('Socket CAN dump')
	fp.skip_executable()

	d_interface := 'vcan0'
	iname      := fp.string('interface', `i`, '${d_interface}', 'The name of the interface, default(${d_interface})')
	additional := fp.finalize()!
	if additional.len > 0 {
		return error('unprocessed args ${additional.join_lines()}')
	}
	return &Dumper{
		iname: iname
	}
}

fn (d Dumper) callback(nbytes int, id u32, payload []u8) {
	now := time.utc()
	println('(${now}.${now.nanosecond:09}) ${id:x}#${payload.hex()}')
}





