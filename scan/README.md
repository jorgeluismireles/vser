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

