library vunit_lib;
context vunit_lib.vunit_context;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use std.textio.all;

library work;

entity test_tb is
	generic (
		runner_cfg : string;
		XFREQ 	: in integer := 50000000               -- board clk frequency
		);
end test_tb;

architecture rtl of test_tb is

	signal i_clk				:	std_logic;	
	signal i_nrst				:	std_logic;

	signal i_GSRI				:	std_logic;



begin

	p_rst:process
	begin
		wait for 1 ns;
		i_nrst <= '0';
		wait for 10 us;
		i_nrst <= '1';
		wait;
	end process;

	p_clk:process
	constant PER2 : time := 500000 us / XFREQ;
	begin
		i_clk <= '0';
		wait for PER2;
		i_clk <= '1';
		wait for PER2;
	end process;

	p_main:process
	begin

		test_runner_setup(runner, runner_cfg);
		while test_suite loop

			if run("test") then
				wait for 1000 us;
			end if;

		end loop;

		wait for 3 us;

		test_runner_cleanup(runner); -- Simulation ends here
	end process;

	e_top:entity work.top
	generic map (
		SIM => TRUE,
		ROMFILE => "../../../asm/build/mos-sim/mos-sim.mi"
--		ROMFILE => "../../../asm/build/mos/mos.mi"
	)
	port map (
		clk_50_i		=> i_clk,
		rst_i			=> not i_nrst,
		uart_tx_o	=> open
	);


--	GSR: entity work.GSR
--	port map (
--		GSRI => i_GSRI
--		);

end rtl;
