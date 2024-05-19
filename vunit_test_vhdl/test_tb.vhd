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
		FREQ 	: in integer := 96000000               -- Actual clk frequency, to time 150us initialization delay
		);
end test_tb;

architecture rtl of test_tb is

	component W9825G6KH port (
		Dq			:	inout std_logic_vector(15 downto 0);
		Addr		:	in		std_logic_vector(12 downto 0); 
		Bs			:  in 	std_logic_vector(1 downto 0); 
		Clk		:  in		std_logic; 
		Cke		:	in		std_logic;
		Cs_n		:	in		std_logic;
		Ras_n		:	in		std_logic;
		Cas_n		:	in		std_logic;
		We_n		:	in		std_logic;
		Dqm		:	in		std_logic_vector(1 downto 0)
	);
	end component;

   signal i_clk           : std_logic;
   signal i_clk_p         : std_logic;
   signal i_resetn        : std_logic;
   signal i_read          : std_logic;
   signal i_write         : std_logic;
   signal i_addr          : std_logic_vector(21 downto 0);
   signal i_din           : std_logic_vector(15 downto 0);
   signal i_byte_write    : std_logic;
   signal i_dout          : std_logic_vector(15 downto 0);
   signal i_busy          : std_logic;

	signal i_sdram_DQ			: std_logic_vector(15 downto 0);
	signal i_sdram_A			: std_logic_vector(12 downto 0); 
	signal i_sdram_BS			: std_logic_vector(1 downto 0); 
	signal i_sdram_Clk		: std_logic; 
	signal i_sdram_CKE		: std_logic;
	signal i_sdram_nCS		: std_logic;
	signal i_sdram_nRAS		: std_logic;
	signal i_sdram_nCAS		: std_logic;
	signal i_sdram_nWE		: std_logic;
	signal i_sdram_DQM		: std_logic_vector(1 downto 0);

	signal i_GSRI				: std_logic;


begin
	p_clk:process
	constant PER2 : time := 500000 us / FREQ;
	begin
		i_clk <= '0';
		wait for PER2;
		i_clk <= '1';
		wait for PER2;
	end process;


	p_main:process
	variable v_time:time;

	procedure DO_INIT is
	begin

		wait for 1 us;

	end procedure;

	procedure DO_WRITE_BYTE(address : integer; data : integer) is
	begin
		

		wait for 1 us;

	end procedure;

	procedure DO_READ_BYTE(address : integer; data : out integer) is
	begin
		
		wait for 1 us;

	end procedure;

	procedure DO_READ_BYTE_C(address : integer; expect_data : integer) is
	variable D:integer;
	begin
		DO_READ_BYTE(address, D);
		assert D = expect_data report "read address " & to_hstring(to_unsigned(address, 21)) & " returned " & to_hstring(to_unsigned(D, 8)) & " expected " & to_hstring(to_unsigned(expect_data, 8));
	end procedure;


	begin

		test_runner_setup(runner, runner_cfg);


		while test_suite loop

			if run("write then read") then

				DO_INIT;

				wait for 250 us;
			end if;

		end loop;

		wait for 3 us;

		test_runner_cleanup(runner); -- Simulation ends here
	end process;

	e_sdramctl:entity work.sdramctl
	generic map (
		CLOCKSPEED => FREQ
		)
	port map (
		Clk		=> i_sdram_Clk,

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



	i_sdram_Clk <= i_clk;

	e_sdram:entity work.W9825G6KH
	port map (
		Dq			=> i_sdram_DQ,
		Addr		=> i_sdram_A,
		Bs			=> i_sdram_BS,
		Clk		=> i_sdram_Clk,
		Cke		=> i_sdram_CKE,
		Cs_n		=> i_sdram_nCS,
		Ras_n		=> i_sdram_nRAS,
		Cas_n		=> i_sdram_nCAS,
		We_n		=> i_sdram_nWE,
		Dqm		=> i_sdram_DQM
    );

--	GSR: entity work.GSR
--	port map (
--		GSRI => i_GSRI
--		);

end rtl;
