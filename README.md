# AtomMiner AM01 hardware design

This is hardware info for [AM01 crypto miner](https://atomminer.com/miner) for everybody who is willing to use it as a kit device and implement their own algos.
If you feel like something is missing, please feel free to let us know.

:warning: **WARNING** any modification and/or alternations of AM01 including, but not limited to PCB, power modules and other components will void your warranty and might render devices unusable.

:warning: **WARNING** any use of custom unsigned bitstreams will void your warranty and might render devices unusable.

[Telegram](https://t.me/atomminer) | 
[Discord](https://discord.gg/pKAfJkb)


AM01 miner has XC7A200T-1FBG484I FPGA chip from Xilinx on board. Following communication options are available to user: JTAG, UART and Cypress FX3 USB controller for communication with the host device.

## Demo projects

Demonstration projects are located in `examples` folder. Each example folder structure:
- **fpga/**: Contains FPGA project file
- **fpga/src**: Contains source files for the Vivado Project.
    -   **fpga/src/sim**: Contains Simulation source files.
    -   **fpga/src/constraints**: Contains XDC constraint files.
    -   **fpga/src/hdl**: Contains Verilog and VHDL source files.
    -   **fpga/src/ip**: Contains XCI files describing IP to be instantiated in non-IPI projects.
    -   **fpga/src/others**: Contains all other required sources, such as memory initialization files.
- **test/**: Contains source files for the Vivado Project.

### Other example projects

Our reference HLS implementations:

* [gr0estl algo](https://github.com/atomminer/Gr0estl-Miner)
* [nist5 algo](https://github.com/atomminer/Nist5-hls)



