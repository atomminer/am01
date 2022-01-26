# ODOCrypt bitstream example for AM01 device

Project was created and implemented with Vivado 2018.2 Stadard Edition (free version).

## License

Actual odocrypt algorithm sources were generated with the tools provided by ODOcrypt team [MentalCollatz / odo-miner](https://github.com/MentalCollatz/odo-miner) and modified to work with AM01 hardware.

## Implementation results

```
Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
---------------------------------------------------------------------------------------------------------------------------------
| Tool Version : Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
| Date         : Thu Jan 27 00:29:05 2022
| Host         : esdev running 64-bit Ubuntu 20.04.3 LTS
| Design       : atomminer_odocrypt
| Device       : 7a200tfbg484-1
| Design State : Routed
---------------------------------------------------------------------------------------------------------------------------------

Utilization Design Information

Table of Contents
-----------------
1. Slice Logic
1.1 Summary of Registers by Type
2. Slice Logic Distribution
3. Memory
4. DSP
5. IO and GT Specific
6. Clocking
7. Specific Feature
8. Primitives
9. Black Boxes
10. Instantiated Netlists

1. Slice Logic
--------------

+----------------------------+-------+-------+-----------+-------+
|          Site Type         |  Used | Fixed | Available | Util% |
+----------------------------+-------+-------+-----------+-------+
| Slice LUTs                 | 36843 |     0 |    133800 | 27.54 |
|   LUT as Logic             | 36832 |     0 |    133800 | 27.53 |
|   LUT as Memory            |    11 |     0 |     46200 |  0.02 |
|     LUT as Distributed RAM |     0 |     0 |           |       |
|     LUT as Shift Register  |    11 |     0 |           |       |
| Slice Registers            | 27522 |     0 |    267600 | 10.28 |
|   Register as Flip Flop    | 27522 |     0 |    267600 | 10.28 |
|   Register as Latch        |     0 |     0 |    267600 |  0.00 |
| F7 Muxes                   |     0 |     0 |     66900 |  0.00 |
| F8 Muxes                   |     0 |     0 |     33450 |  0.00 |
+----------------------------+-------+-------+-----------+-------+


1.1 Summary of Registers by Type
--------------------------------

+-------+--------------+-------------+--------------+
| Total | Clock Enable | Synchronous | Asynchronous |
+-------+--------------+-------------+--------------+
| 0     |            _ |           - |            - |
| 0     |            _ |           - |          Set |
| 0     |            _ |           - |        Reset |
| 0     |            _ |         Set |            - |
| 0     |            _ |       Reset |            - |
| 0     |          Yes |           - |            - |
| 0     |          Yes |           - |          Set |
| 0     |          Yes |           - |        Reset |
| 7     |          Yes |         Set |            - |
| 27581 |          Yes |       Reset |            - |
+-------+--------------+-------------+--------------+


2. Slice Logic Distribution
---------------------------

+-------------------------------------------+-------+-------+-----------+-------+
|                 Site Type                 |  Used | Fixed | Available | Util% |
+-------------------------------------------+-------+-------+-----------+-------+
| Slice                                     | 10451 |     0 |     33450 | 31.24 |
|   SLICEL                                  |  6586 |     0 |           |       |
|   SLICEM                                  |  3865 |     0 |           |       |
| LUT as Logic                              | 36832 |     0 |    133800 | 27.53 |
|   using O5 output only                    |     0 |       |           |       |
|   using O6 output only                    | 33493 |       |           |       |
|   using O5 and O6                         |  3339 |       |           |       |
| LUT as Memory                             |    11 |     0 |     46200 |  0.02 |
|   LUT as Distributed RAM                  |     0 |     0 |           |       |
|   LUT as Shift Register                   |    11 |     0 |           |       |
|     using O5 output only                  |     4 |       |           |       |
|     using O6 output only                  |     7 |       |           |       |
|     using O5 and O6                       |     0 |       |           |       |
| LUT Flip Flop Pairs                       | 22477 |     0 |    133800 | 16.80 |
|   fully used LUT-FF pairs                 |  2969 |       |           |       |
|   LUT-FF pairs with one unused LUT output | 19460 |       |           |       |
|   LUT-FF pairs with one unused Flip Flop  | 19182 |       |           |       |
| Unique Control Sets                       |    21 |       |           |       |
+-------------------------------------------+-------+-------+-----------+-------+
* Note: Review the Control Sets Report for more information regarding control sets.


3. Memory
---------

+-------------------+------+-------+-----------+-------+
|     Site Type     | Used | Fixed | Available | Util% |
+-------------------+------+-------+-----------+-------+
| Block RAM Tile    |  211 |     0 |       365 | 57.81 |
|   RAMB36/FIFO*    |    1 |     1 |       365 |  0.27 |
|     RAMB36E1 only |    1 |       |           |       |
|   RAMB18          |  420 |     0 |       730 | 57.53 |
|     RAMB18E1 only |  420 |       |           |       |
+-------------------+------+-------+-----------+-------+
* Note: Each Block RAM Tile only has one FIFO logic available and therefore can accommodate only one FIFO36E1 or one FIFO18E1. However, if a FIFO18E1 occupies a Block RAM Tile, that tile can still accommodate a RAMB18E1


4. DSP
------

+-----------+------+-------+-----------+-------+
| Site Type | Used | Fixed | Available | Util% |
+-----------+------+-------+-----------+-------+
| DSPs      |    0 |     0 |       740 |  0.00 |
+-----------+------+-------+-----------+-------+


5. IO and GT Specific
---------------------

+-----------------------------+------+-------+-----------+-------+
|          Site Type          | Used | Fixed | Available | Util% |
+-----------------------------+------+-------+-----------+-------+
| Bonded IOB                  |   40 |    40 |       285 | 14.04 |
|   IOB Master Pads           |   21 |       |           |       |
|   IOB Slave Pads            |   19 |       |           |       |
|   IOB Flip Flops            |   66 |    66 |           |       |
| Bonded IPADs                |    0 |     0 |        14 |  0.00 |
| Bonded OPADs                |    0 |     0 |         8 |  0.00 |
| PHY_CONTROL                 |    0 |     0 |        10 |  0.00 |
| PHASER_REF                  |    0 |     0 |        10 |  0.00 |
| OUT_FIFO                    |    0 |     0 |        40 |  0.00 |
| IN_FIFO                     |    0 |     0 |        40 |  0.00 |
| IDELAYCTRL                  |    0 |     0 |        10 |  0.00 |
| IBUFDS                      |    0 |     0 |       274 |  0.00 |
| GTPE2_CHANNEL               |    0 |     0 |         4 |  0.00 |
| PHASER_OUT/PHASER_OUT_PHY   |    0 |     0 |        40 |  0.00 |
| PHASER_IN/PHASER_IN_PHY     |    0 |     0 |        40 |  0.00 |
| IDELAYE2/IDELAYE2_FINEDELAY |    0 |     0 |       500 |  0.00 |
| IBUFDS_GTE2                 |    0 |     0 |         2 |  0.00 |
| ILOGIC                      |   33 |    33 |       285 | 11.58 |
|   IFF_Register              |   33 |    33 |           |       |
| OLOGIC                      |   33 |    33 |       285 | 11.58 |
|   OUTFF_Register            |   33 |    33 |           |       |
+-----------------------------+------+-------+-----------+-------+


6. Clocking
-----------

+------------+------+-------+-----------+-------+
|  Site Type | Used | Fixed | Available | Util% |
+------------+------+-------+-----------+-------+
| BUFGCTRL   |    4 |     0 |        32 | 12.50 |
| BUFIO      |    0 |     0 |        40 |  0.00 |
| MMCME2_ADV |    2 |     0 |        10 | 20.00 |
| PLLE2_ADV  |    0 |     0 |        10 |  0.00 |
| BUFMRCE    |    0 |     0 |        20 |  0.00 |
| BUFHCE     |    0 |     0 |       120 |  0.00 |
| BUFR       |    0 |     0 |        40 |  0.00 |
+------------+------+-------+-----------+-------+


7. Specific Feature
-------------------

+-------------+------+-------+-----------+--------+
|  Site Type  | Used | Fixed | Available |  Util% |
+-------------+------+-------+-----------+--------+
| BSCANE2     |    0 |     0 |         4 |   0.00 |
| CAPTUREE2   |    0 |     0 |         1 |   0.00 |
| DNA_PORT    |    1 |     0 |         1 | 100.00 |
| EFUSE_USR   |    0 |     0 |         1 |   0.00 |
| FRAME_ECCE2 |    0 |     0 |         1 |   0.00 |
| ICAPE2      |    0 |     0 |         2 |   0.00 |
| PCIE_2_1    |    0 |     0 |         1 |   0.00 |
| STARTUPE2   |    0 |     0 |         1 |   0.00 |
| XADC        |    1 |     0 |         1 | 100.00 |
+-------------+------+-------+-----------+--------+


8. Primitives
-------------

+------------+-------+---------------------+
|  Ref Name  |  Used | Functional Category |
+------------+-------+---------------------+
| FDRE       | 27581 |        Flop & Latch |
| LUT6       | 18818 |                 LUT |
| LUT2       | 13729 |                 LUT |
| LUT3       |  6262 |                 LUT |
| LUT4       |   821 |                 LUT |
| LUT5       |   511 |                 LUT |
| RAMB18E1   |   420 |        Block Memory |
| CARRY4     |    96 |          CarryLogic |
| IBUF       |    37 |                  IO |
| OBUFT      |    32 |                  IO |
| LUT1       |    30 |                 LUT |
| FDSE       |     7 |        Flop & Latch |
| SRLC32E    |     6 |  Distributed Memory |
| SRL16E     |     5 |  Distributed Memory |
| BUFG       |     4 |               Clock |
| OBUF       |     3 |                  IO |
| MMCME2_ADV |     2 |               Clock |
| XADC       |     1 |              Others |
| RAMB36E1   |     1 |        Block Memory |
| DNA_PORT   |     1 |              Others |
+------------+-------+---------------------+


9. Black Boxes
--------------

+----------+------+
| Ref Name | Used |
+----------+------+


10. Instantiated Netlists
-------------------------

+----------------------+------+
|       Ref Name       | Used |
+----------------------+------+
| xadc_artix200_v0     |    1 |
| usb3_system_ram      |    1 |
| clk_pclk             |    1 |
| artix200_v3_clocking |    1 |
+----------------------+------+
```