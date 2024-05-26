//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9.02 
//Created Time: 2024-05-23 20:00:19
create_clock -name CLOCK_BRD_50 -period 20 -waveform {0 10} [get_ports {clk_50_i}]

create_generated_clock -name clock_fast -source [get_ports {clk_50_i}] -master_clock CLOCK_BRD_50 -divide_by 2 -multiply_by 5 [get_nets {i_fbsyscon.clk}]

set_multicycle_path -from [get_regs {e_cpu/e_cpu_0/*}] -to [get_regs {e_cpu/e_cpu_0/*}]  -setup -end 3
set_multicycle_path -from [get_regs {e_cpu/e_cpu_0/*}] -to [get_regs {e_cpu/e_cpu_0/*}]  -hold -end 2

set_multicycle_path -from [get_pins {e_cpu/e_cpu_0/opcInfo_0_*/DO*}] -to [get_regs {e_cpu/e_cpu_0/*}]  -setup -end 3
set_multicycle_path -from [get_pins {e_cpu/e_cpu_0/opcInfo_0_*/DO*}] -to [get_regs {e_cpu/e_cpu_0/*}]  -hold -end 2
