# Socket CAN

Socket CAN is only for [Linux](https://docs.kernel.org/networking/can.html).

## Virtual CAN

Virtual ports are available to test sending and receiving CAN messages from apps.

### Activate virtual can 0

File `cmd/vcan0.sh`

```
sudo modprobe vcan;
sudo ip link add dev vcan0 type vcan;
sudo ip link set up vcan0;
ip link | grep vcan
```

Run only once and expect somenthing like this:
```
$ ./cmd/vcan0.sh 
4: vcan0: <NOARP,UP,LOWER_UP> mtu 72 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
```

### Install can-utils

Userland application to send and receive CAN messages

```
$ git clone  https://github.com/linux-can/can-utils.
$ cd can-utils
$ make
...
$ sudo make install
...
```

#### Run `candump` app:

In console #1 run a CAN messages listener:
```
$ candump -t A any
```

#### `cansend` app

In console #2 run a CAN message sender:
```
$ cansend vcan0 0000A1B2#3450
```

Check in console #1 the reception of message from console #2 (first_row)
```
$ candump -t A any
 (2025-07-24 11:03:53.379740)  vcan0  0000A1B2   [2]  34 50
```

### V app CAN sender

File: `cmd/scan_sender.v`

```v
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
	write := socket.write_29(can_id, payload) or {
		panic('sender error: ${err}')
	}
	println('send: ${write}')
}
```

Run in console #3:

```
$ v run cmd/scan_sender.v
12345678#0102030405060708
```

Check in console #1 the reception of message from console #3 (second_row)
```
 (2025-07-24 11:03:53.379740)  vcan0  0000A1B2   [2]  34 50
 (2025-07-24 11:28:31.420828)  vcan0  12345678   [8]  01 02 03 04 05 06 07 08
```

### V app CAN dump

File: `cmd/scan_dump.v`

```v
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
```

Example receiving from any sender:
```
$ v run cmd/scan_dump.v 
scan_dump @ vcan0
(2025-07-24 18:49:50.566585843) 12345678#0102030405060708
(2025-07-24 18:49:50.936020865) 12345678#0102030405060708
(2025-07-24 18:49:51.243260779) 12345678#0102030405060708
```

## Real CAN Raspberry 

Follow instructions for [Pi with CAN Hat](https://www.pragmaticlinux.com/2021/10/can-communication-on-the-raspberry-pi-with-socketcan/)

```
$ lsmod | grep "can"
can_raw                20480  1
can                    24576  1 can_raw
vcan                   12288  0
can_dev                49152  2 mcp251x,vcan
```
For 100khz CAN equipment:
```
$ sudo ip link set can0 type can bitrate 100000 restart-ms 100
$ sudo ip link set up can0
$ ip a | grep can0
3: can0: <NOARP,UP,LOWER_UP,ECHO> mtu 16 qdisc pfifo_fast state UP group default qlen 10
7: vcan0: <NOARP,UP,LOWER_UP> mtu 72 qdisc noqueue state UNKNOWN group default qlen 1000
```

Connect a real CAN equipment that send messages to the net. Inspect the traffic with the dump:

```
pi@raspberrypi:~/vser $ v run scan/cmd/scan_dump.v -i can0
scan_dump @ can0
(2025-07-24 20:45:03.166895298) e000021#
(2025-07-24 20:45:03.168136103) 12345678#01020304050607
(2025-07-24 20:45:03.169365130) e000029#0100070000
(2025-07-24 20:45:03.170613509) e000029#0201070000
(2025-07-24 20:45:03.171852740) e000029#0302070000
(2025-07-24 20:45:14.748800014) ee00020#020300
(2025-07-24 20:45:14.769495962) e00002e#02012828000b
(2025-07-24 20:45:14.803536342) e000029#02410884035a
(2025-07-24 20:45:15.173279726) e00002d#0241b0360001
...
```
