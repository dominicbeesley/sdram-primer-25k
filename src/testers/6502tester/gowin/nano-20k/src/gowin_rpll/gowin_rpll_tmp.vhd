--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.11 (64-bit)
--Part Number: GW2AR-LV18QN88C8/I7
--Device: GW2AR-18
--Device Version: C
--Created Time: Tue Feb  4 14:58:09 2025

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component pll1
    port (
        clkout: out std_logic;
        lock: out std_logic;
        clkoutp: out std_logic;
        reset: in std_logic;
        clkin: in std_logic;
        psda: in std_logic_vector(3 downto 0);
        dutyda: in std_logic_vector(3 downto 0);
        fdly: in std_logic_vector(3 downto 0)
    );
end component;

your_instance_name: pll1
    port map (
        clkout => clkout,
        lock => lock,
        clkoutp => clkoutp,
        reset => reset,
        clkin => clkin,
        psda => psda,
        dutyda => dutyda,
        fdly => fdly
    );

----------Copy end-------------------
