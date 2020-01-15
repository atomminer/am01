# AtomMiner AM01 hardware design

This is hardware info for [AM01 crypto miner](https://atomminer.com/miner) for everybody who is willing to use it as a kit device and implement their own algos.
If you feel like something is missing, please feel free to let us know.

:warning: **WARNING** any modification and/or alternations of AM01 including, but not limited to PCB, power modules and other components will void your warranty and might render devices unusable.

[Telegram](https://t.me/atomminer)
[Discord](https://discord.gg/pKAfJkb)


AM01 miner has XC7A200T-1FBG484I FPGA chip from Xilinx on board. Following communication options are available to user: JTAG, UART and Cypress FX3 USB controller for communication with the host device.


## Demo projects

Our reference HLS implementations:

* [gr0estl algo](https://github.com/atomminer/Gr0estl-Miner)
* [nist5 algo](https://github.com/atomminer/Nist5-hls)

We can recommend to check [odocrypt from DGB team](https://github.com/MentalCollatz/odo-miner) as well since odo project that can be easily implemented in AM01 miner.

We will publish more demo projects here in the future.



