//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9.02 
//Created Time: 2024-05-20 19:27:07
create_clock -name CLOCK_BRD_50 -period 20 -waveform {0 10} [get_ports {clk_50_i}]
