--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.9.02
--Part Number: GW5A-LV25MG121NC1/I0
--Device: GW5A-25
--Device Version: A
--Created Time: Sun May 26 23:47:21 2024

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component pll1
    port (
        lock: out std_logic;
        clkout0: out std_logic;
        clkout1: out std_logic;
        clkin: in std_logic;
        reset: in std_logic;
        pssel: in std_logic_vector(2 downto 0);
        psdir: in std_logic;
        pspulse: in std_logic
    );
end component;

your_instance_name: pll1
    port map (
        lock => lock_o,
        clkout0 => clkout0_o,
        clkout1 => clkout1_o,
        clkin => clkin_i,
        reset => reset_i,
        pssel => pssel_i,
        psdir => psdir_i,
        pspulse => pspulse_i
    );

----------Copy end-------------------
