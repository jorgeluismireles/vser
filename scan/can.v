module scan

import encoding.binary
import encoding.hex

pub struct Can {
	id   u32
pub:
	data Data
}

pub fn new_can(id u32, bytes []u8) !Can {
	if bytes.len > 8 {
		return error('Invalid bytes size:${bytes.hex}')
	}
	return Can{
		id:   id,
		data: new_data(bytes)
	}
}

// new_can_from_string returns a can from a string like id#data
// where id is 29-bits hexadecimal number and data are empty to eight
// data bytes in hexadecimal
pub fn new_can_from_string(can string) !Can {
	parts := can.split('#')
	ids := hex.decode(parts[0])!
	if ids.len > 4 {
		return error('can id array greater than 4')
	}
	data := hex.decode(parts[1])!
	mut id := u32(0)
	for i := 0; i < ids.len; i++ {
		part := u32(ids[i]) << (8 * (ids.len - 1 - i))
		id |= part
	}
	return new_can(id, data)
}

pub fn (m Can) get_id() u32 {
	return m.id
}

pub fn (m Can) get_data() Data {
	return m.data
}

//const twenty_nine_bits = u32(0x1FFFFFFF)

pub fn (m Can) socketcan() string {
	ids := binary.big_endian_get_u32(m.id & twenty_nine_bits)
	return '${ids.hex()}#${m.data.bytes.hex()}'
}

pub fn (m Can) str() string {
	return '${m.data.sec}.${m.data.nanos:09d}: ${m.id:x}#${m.data.bytes.hex()}'
}

//
// Data
//
pub struct Data {
pub:
	bytes []u8
	sec   i64
	nanos int
}

pub fn new_data(bytes []u8) Data {
	$if linux {
		// copied from time/time_nix.c.v linux_utc()
		// we don't need to calculate ymd/hms yet
		//mut ts := C.timespec{}
		//C.clock_gettime(C.CLOCK_REALTIME, &ts)
		return Data{
			bytes: bytes
			sec:   0//i64(ts.tv_sec)
			nanos: 0//int(ts.tv_nsec)
		}
	}
	return Data{
		bytes: bytes
	}
}

