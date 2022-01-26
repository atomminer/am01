# ODOCrypt bistream test script

Bitstream is created for ODO epoch 1642464000 and test block in this file is provided for that exact epoch and can be validated against software provided by [MentalCollatz](https://github.com/MentalCollatz/odo-miner)

## Install

To install dependencies navigate to test folder and run:
```
npm install
```

To start test simply start:
```
node index.js
```

## Bitstream info

Only raw binary bitstreams in SelectMAP32 format without header are supported by AM01. All other bitstream formats are **not** supported: .bit .hex .mcs 

Compressed bistreams are not supported.

**WARNING** Please make sure that your binary files are in SelectMAP32 format before configuring device.

More info about bitstream formats can be found from [UG479](https://www.xilinx.com/support/documentation/user_guides/ug470_7Series_Config.pdf) and [XAPP583](https://www.xilinx.com/support/documentation/application_notes/xapp583-fpga-configuration.pdf).

