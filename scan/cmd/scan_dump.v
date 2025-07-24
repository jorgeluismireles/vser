module main

import time

import scan

fn callback(nbytes int, id u32, payload []u8) {
	now := time.utc()
	println('(${now}.${now.nanosecond:09}) ${id:x}#${payload.hex()}')
}

fn main() {
	cfg := scan.Cfg{
		name: 'vcan0'
	}
	socket := scan.new_socket(cfg)!
	println('scan_dump @ ${cfg.name}')
	socket.read_29(callback)! // blocks here
	socket.close()
}

