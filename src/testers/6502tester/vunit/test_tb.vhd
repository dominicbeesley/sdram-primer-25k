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

	signal	i_sdram_clk		:	std_logic;
	signal	i_sdram_DQ		:	std_logic_vector(15 downto 0);
	signal	i_sdram_A		:	std_logic_vector(12 downto 0); 
	signal	i_sdram_BS		:	std_logic_vector(1 downto 0); 
	signal	i_sdram_CKE		:	std_logic;
	signal	i_sdram_nCS		:	std_logic;
	signal	i_sdram_nRAS	:	std_logic;
	signal	i_sdram_nCAS	:	std_logic;
	signal	i_sdram_nWE		:	std_logic;
	signal	i_sdram_DQM		:	std_logic_vector(1 downto 0);


begin

   p_gsri:process
   begin
      i_GSRI <= '0';
      wait for 1 us;
      i_GSRI <= '1';
      wait;
   end process;


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

		sdram_clk_o		=> i_sdram_clk,
		sdram_DQ_io		=> i_sdram_DQ,
		sdram_A_o		=> i_sdram_A,
		sdram_BS_o		=> i_sdram_BS,
		sdram_CKE_o		=> i_sdram_CKE,
		sdram_nCS_o		=> i_sdram_nCS,
		sdram_nRAS_o	=> i_sdram_nRAS,
		sdram_nCAS_o	=> i_sdram_nCAS,
		sdram_nWE_o		=> i_sdram_nWE,
		sdram_DQM_o		=> i_sdram_DQM

	);

	e_sdram:entity work.W9825G6KH
	port map (
		Dq			=> i_sdram_DQ,
		Addr		=> i_sdram_A,
		Bs			=> i_sdram_BS,
		Clk		=> i_sdram_clk,
		Cke		=> i_sdram_CKE,
		Cs_n		=> i_sdram_nCS,
		Ras_n		=> i_sdram_nRAS,
		Cas_n		=> i_sdram_nCAS,
		We_n		=> i_sdram_nWE,
		Dqm		=> i_sdram_DQM
    );


	GSR: entity work.GSR
	port map (
		GSRI => i_GSRI
		);

end rtl;
