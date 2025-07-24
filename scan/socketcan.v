module scan

import encoding.binary

const twenty_nine_bits = u32(0x1FFFFFFF)

pub struct Cfg {
pub:
	name string
}

pub fn (c Cfg) modprobe_for_name() string {
	return 'sudo modprobe vcan
sudo ip link add dev ${c.name} type vcan
sudo ip link set up ${c.name}'
}

pub struct Socket {
mut:
	fd   int 
	addr &C.sockaddr_can = unsafe { nil }
}

pub fn new_socket(cfg Cfg) !&Socket {
	fd := new_socketcan() or {
		return error('vcan: new_socketcan')
	}
	ifr := new_interface(cfg.name) or {
		return error('${err}')
	}
	mut addr := C.sockaddr_can{
		can_family:  C.AF_CAN
		can_ifindex: ifr.ifr_ifindex
	}
	if C.bind(fd, voidptr(&addr), sizeof(addr)) < 0 {
		return error("vcan: bind")
	}
	return &Socket{
		fd:   fd
		addr: &addr
	}
}

pub fn (s Socket) write_29(id u32, payload []u8) !string {
	ids := binary.big_endian_get_u32(id & twenty_nine_bits)
	frame := '${ids.hex()}#${payload.hex()}'

	cu := &C.cu_t{}
	mtu := C.parse_canframe(&char(frame.str), cu)
	if mtu > C.CAN_MTU {
		return error('mtu > ${C.CAN_MTU}')
	}
	if mtu < 0 {
		return error('Invalid mtu ${mtu}')
	}
	if C.write(s.fd, cu, mtu) != mtu {
		return error('write')
	}
	return frame
}

type CallbackFn = fn(nbytes int, id u32, payload []u8)

@[heap]
@[direct_array_access]
pub fn (s Socket) read_29(callback CallbackFn) ! {

	// see code at v/vlib/picoev/loop_linux.c.v update_events
	mut ev := C.epoll_event{}

	//ev.data.fd = s.fd
	// error: struct `C.epoll_data` was declared as private to module `picoev`, so it can not be used inside module `vcan`

	epoll_fd := C.epoll_create(1)
	if epoll_fd < 0 {
		return error("epoll_create")
	}

	mut epoll_ret := C.epoll_ctl(epoll_fd, C.EPOLL_CTL_MOD, s.fd, &ev)
	if epoll_ret != 0 {
		assert C.errno == C.ENOENT
		epoll_ret = C.epoll_ctl(epoll_fd, C.EPOLL_CTL_ADD, s.fd, &ev)
		assert epoll_ret == 0
	}

	events := [16]C.epoll_event{}
	timeout_ms := 1_000

	mut msg := C.msghdr{}
	mut iov := C.iovec{}
	// these settings are static and can be held out of the hot path
	mut cu := C.cu_t{}
	iov.iov_base = &cu
	msg.msg_iov = &iov
	msg.msg_iovlen = 1

	// see code at v/vlib/picoev/loop_linux.c.v poll_once(max_wait_in_sec)
	for {
		nevents := C.epoll_wait(epoll_fd, &events[0], events.len, timeout_ms)
		if nevents == -1 {
			return error('epoll_wait: timeout')
		}

		for i := 0; i < nevents; i++ {
			//mut event := events[i]
			iov.iov_len = int(sizeof(cu)) // 2060
			
			msg.msg_flags = 0;
			nbytes := C.recvmsg(s.fd, &msg, 0)
			if nbytes < 0 {
				return error('recvmsg')
			}
			id := cu.cc.can_id & twenty_nine_bits
			payload := cu.cc.data[0 .. cu.cc.len]

			callback(nbytes, id, payload)
		}
	}
}

// close closes the Socket socket
pub fn (s Socket) close() {
	C.close(s.fd)
}
