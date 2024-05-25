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
		PHASE   : in real := 190.0;						-- degrees of phase lag for clk_p
		FREQ 	: in integer := 100000000               -- Actual clk frequency, to time 150us initialization delay
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
	signal i_sdram_CKE		: std_logic;
	signal i_sdram_nCS		: std_logic;
	signal i_sdram_nRAS		: std_logic;
	signal i_sdram_nCAS		: std_logic;
	signal i_sdram_nWE		: std_logic;
	signal i_sdram_DQM		: std_logic_vector(1 downto 0);

	signal i_GSRI				: std_logic;

	signal i_ctl_stall		:	std_logic;
	signal i_ctl_cyc			:	std_logic;
	signal i_ctl_we			:	std_logic;
	signal i_ctl_A				:	std_logic_vector(24 downto 0);
	signal i_ctl_D_wr			:	std_logic_vector(7 downto 0);
	signal i_ctl_D_rd			:	std_logic_vector(7 downto 0);
	signal i_ctl_ack			:	std_logic;
	signal i_ctl_rfsh			:  std_logic;


	constant t_PER_lag : time := (1000000 us / FREQ) * (PHASE / 360.0);


begin
	p_clk:process
	constant PER2 : time := 500000 us / FREQ;
	begin
		i_clk <= '0';
		wait for PER2;
		i_clk <= '1';
		wait for PER2;
	end process;

	i_clk_p <= transport i_clk after t_PER_lag;

	p_main:process
	variable v_time:time;
	variable	test_d	: std_logic_vector(7 downto 0);
	variable I:integer;

	procedure DO_INIT is
	begin

		i_ctl_cyc 	<= '0';
		i_ctl_we  	<= '0';
		i_ctl_A		<= (others => '0');
		i_ctl_D_wr	<= (others => '0');


		wait for 10 us;

		wait until i_ctl_stall = '0';

		wait for 2 us;

	end procedure;


	procedure DO_READ_BYTE(address : std_logic_vector(24 downto 0); data : out std_logic_vector(7 downto 0)) is
	variable v_iter : natural := 0;
	begin

		wait until rising_edge(i_clk);

		wait for 0 ns;

		i_ctl_cyc 	<= '1';
		i_ctl_we  	<= '0';
		i_ctl_A		<= address;
		i_ctl_D_wr	<= (others => '-');

		wait until rising_edge(i_clk);

		v_iter := 0;
		while i_ctl_stall /= '0' loop
			wait until rising_edge(i_clk);
			v_iter := v_iter + 1;
			if v_iter > 1000 then
				report "Failed waiting for stall" severity error;
			end if;
		end loop;


		wait until rising_edge(i_clk);
		-- wait for ack

		i_ctl_cyc 	<= '0';

		v_iter := 0;
		while i_ctl_ack /= '1' loop
			wait until rising_edge(i_clk);
			v_iter := v_iter + 1;
			if v_iter > 1000 then
				report "Failed waiting for ack" severity error;
			end if;
		end loop;

		data := i_ctl_D_rd;
		
		report "read address " & to_hstring(unsigned(address)) & " returned " & to_hstring(unsigned(data)) severity note;
		
		wait until rising_edge(i_clk);


	end procedure;

	procedure DO_WRITE_BYTE(address : std_logic_vector(24 downto 0); data : std_logic_vector(7 downto 0)) is
	variable v_iter : natural := 0;
	begin
		

		wait until rising_edge(i_clk);

		wait for 1 ns;

		i_ctl_cyc 	<= '1';
		i_ctl_we  	<= '1';
		i_ctl_A		<= address;
		i_ctl_D_wr	<= data;

		wait until rising_edge(i_clk);


		v_iter := 0;
		while i_ctl_stall /= '0' loop
			wait until rising_edge(i_clk);
			v_iter := v_iter + 1;
			if v_iter > 1000 then
				report "Failed waiting for stall" severity error;
			end if;
		end loop;

		wait for 1 ns;

		-- wait for ack

		i_ctl_cyc 	<= '0';

		v_iter := 0;
		while i_ctl_ack /= '1' loop
			wait until rising_edge(i_clk);
			v_iter := v_iter + 1;
			if v_iter > 1000 then
				report "Failed waiting for ack" severity error;
			end if;
		end loop;



	end procedure;



	procedure DO_READ_BYTE_C(address : std_logic_vector(24 downto 0); expect_data : std_logic_vector(7 downto 0)) is
	variable D:std_logic_vector(7 downto 0);
	begin
		DO_READ_BYTE(address, D);
		assert D = expect_data report "read address " & to_hstring(unsigned(address)) & " returned " & to_hstring(unsigned(D)) & " expected " & to_hstring(unsigned(expect_data));
	end procedure;

	FUNCTION ADDR(a:integer) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(a, 25));
	end function ADDR;


	begin

		test_runner_setup(runner, runner_cfg);


		while test_suite loop

			if run("write then read") then

				DO_INIT;

				i_ctl_rfsh	 <= '1';

				DO_WRITE_BYTE(ADDR(16#12345#), x"23");
				DO_WRITE_BYTE(ADDR(16#12346#), x"45");
				DO_WRITE_BYTE(ADDR(16#12347#), x"BE");
				DO_WRITE_BYTE(ADDR(16#12348#), x"EF");

				wait for 1 us;

				DO_READ_BYTE_C(ADDR(16#12345#), x"23");				
				DO_READ_BYTE_C(ADDR(16#12346#), x"45");
				DO_READ_BYTE_C(ADDR(16#12347#), x"BE");
				DO_READ_BYTE_C(ADDR(16#12348#), x"EF");

				wait for 1 us;
			elsif run("multibank") then

				DO_INIT;

				i_ctl_rfsh	 <= '1';

				FOR I in 0 TO 255 loop
					DO_WRITE_BYTE(ADDR(I * 16#20000#), std_logic_vector(to_unsigned(I,8)));
				END LOOP;

				wait for 1 us;

				FOR I in 0 TO 255 loop
					DO_READ_BYTE_C(ADDR(I * 16#20000#), std_logic_vector(to_unsigned(I,8)));
				END LOOP;

				wait for 1 us;
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
		Clk				=> i_clk,

		sdram_DQ_io		=> i_sdram_DQ,
		sdram_A_o		=> i_sdram_A,
		sdram_BS_o		=> i_sdram_BS,
		sdram_CKE_o		=> i_sdram_CKE,
		sdram_nCS_o		=> i_sdram_nCS,
		sdram_nRAS_o	=> i_sdram_nRAS,
		sdram_nCAS_o	=> i_sdram_nCAS,
		sdram_nWE_o		=> i_sdram_nWE,
		sdram_DQM_o		=> i_sdram_DQM,

		ctl_rfsh_i		=> i_ctl_rfsh,
		ctl_reset_i		=> '0',
		ctl_stall_o		=> i_ctl_stall,
		ctl_cyc_i		=> i_ctl_cyc,
		ctl_we_i			=> i_ctl_we,
		ctl_A_i			=> i_ctl_A,
		ctl_D_wr_i		=> i_ctl_D_wr,
		ctl_D_rd_o		=> i_ctl_D_rd,
		ctl_ack_o		=> i_ctl_ack
    );




	e_sdram:entity work.W9825G6KH
	port map (
		Dq			=> i_sdram_DQ,
		Addr		=> i_sdram_A,
		Bs			=> i_sdram_BS,
		Clk		=> i_clk_p,
		Cke		=> i_sdram_CKE,
		Cs_n		=> i_sdram_nCS,
		Ras_n		=> i_sdram_nRAS,
		Cas_n		=> i_sdram_nCAS,
		We_n		=> i_sdram_nWE,
		Dqm		=> i_sdram_DQM
		--Dqm		=> "00"
    );

--	GSR: entity work.GSR
--	port map (
--		GSRI => i_GSRI
--		);

end rtl;
