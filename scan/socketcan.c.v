module scan

// This seems to work with "updated linux/can definitions"
// instead those of /usr/include/...
#flag -I @VMODROOT/scan/can-utils/
#flag -I @VMODROOT/scan/can-utils/include/
#flag -I @VMODROOT/scan/can-utils/include/linux/
#flag -I @VMODROOT/scan/can-utils/include/linux/can/

#include <net/if.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/error.h>
#include <lib.h>

#flag @VMODROOT/scan/can-utils/lib.o

fn C.bind(s int, v voidptr, size u32) int
fn C.if_nametoindex(const_format &char) int
fn C.ioctl(s int, SIOCGIFMTU int, ...voidptr) int 
fn C.epoll_create(int) int
fn C.epoll_ctl(int, int, int, voidptr) int
fn C.epoll_wait(int, voidptr, int, int) int
fn C.parse_canframe(cs &char, cu &&C.cu_t) int
fn C.recvmsg(int, voidptr, int) int
//fn C.setsockopt(int, int, int, voidptr, int) remove to veb to work!
fn C.socket(voidptr, voidptr, int) int // correct to veb to work!
fn C.write(int, voidptr, int) int

struct C.can_frame {
	can_id u32
	len    u8
	data   [8]u8
}

/**
 * struct canxl_frame - CAN with e'X'tended frame 'L'ength frame structure
 * @prio:  11 bit arbitration priority with zero'ed CAN_*_FLAG flags / VCID
 * @flags: additional flags for CAN XL
 * @sdt:   SDU (service data unit) type
 * @len:   frame payload length in byte (CANXL_MIN_DLEN .. CANXL_MAX_DLEN)
 * @af:    acceptance field
 * @data:  CAN XL frame payload (CANXL_MIN_DLEN .. CANXL_MAX_DLEN byte)
 *
 * @prio shares the same position as @can_id from struct can[fd]_frame.
 */
//struct canxl_frame {
//	canid_t prio;  /* 11 bit priority for arbitration / 8 bit VCID */
//	__u8    flags; /* additional flags for CAN XL */
//	__u8    sdt;   /* SDU (service data unit) type */
//	__u16   len;   /* frame payload length in byte */
//	__u32   af;    /* acceptance field */
//	__u8    data[CANXL_MAX_DLEN];
//};

@[typedef]
pub struct C.cu_t{
	cc C.can_frame
	//fd C.canfd_frame
	//xl C.canxl_frame
}

struct C.ifreq {
	ifr_name    [16]u8
mut:
	ifr_ifindex int
}

@[packed]
struct C.sockaddr_can {
	can_family  int
	can_ifindex int
}

// Be careful to set as picoev using when veb is used in api/server.v 
@[typedef]
pub union C.epoll_data_t {
mut:
	ptr  voidptr
	fd   int
	//u32  u32
	//u64  u64
} 

@[packed]
pub struct C.epoll_event {
mut:
	events u32 = u32(C.EPOLLIN)
	data   C.epoll_data_t = C.epoll_data_t{}
}

@[heap]
struct C.iovec{
mut: 
	iov_base voidptr
	iov_len  int
}

@[heap]
struct C.msghdr { // <sys/socket.h>
mut:
	msg_name       voidptr // Optional address
	msg_namelen    u32     // C.socklen_t // Size of address
	msg_iov        voidptr // Scatter/gather array
	msg_iovlen     int     // # elements in msg_iov
	msg_control    voidptr // Ancillary data, see below
	msg_controllen int     // Ancillary data buffer len
	msg_flags      int     // Flags on received message
}

fn new_socketcan() !int {
	fd := C.socket(voidptr(C.PF_CAN), voidptr(C.SOCK_RAW), C.CAN_RAW)
	if fd <= 0 {
		return error('socket can error')
	}
	return fd
}

fn new_interface(interface_name string) !&C.ifreq {
	mut name := [16]u8{}
	b := interface_name.bytes()
	for p := 0; p < 16 && p < b.len; p++ {
		name[p] = b[p]
	}
	// get the interface index given the name
	index := C.if_nametoindex(interface_name.str)
	if index == 0 {
		return error('Invalid index for name ${interface_name}')
	}
	return &C.ifreq{
		ifr_name:    name
		ifr_ifindex: index
	}
}

