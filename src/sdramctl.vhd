
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

library work;
use work.common.all;

entity sdramctl is
	generic (
		CLOCKSPEED : natural
		);
	port (
		Clk		:  in		std_logic; 


		-- sdram interface
		sdram_DQ_io			:	inout std_logic_vector(15 downto 0);
		sdram_A_o			:	out	std_logic_vector(12 downto 0); 
		sdram_BS_o			:  out 	std_logic_vector(1 downto 0); 
		sdram_CKE_o			:	out	std_logic;
		sdram_nCS_o			:	out	std_logic;
		sdram_nRAS_o		:	out	std_logic;
		sdram_nCAS_o		:	out	std_logic;
		sdram_nWE_o			:	out	std_logic;
		sdram_DQM_o			:	out	std_logic_vector(1 downto 0);

		-- cpu interface

		ctl_busy_o			: 	out	std_logic
	);

end sdramctl;

architecture rtl of sdramctl is

	constant tck : time := 1 sec / CLOCKSPEED;
	
	constant trp : time := 15 ns;
	constant trc : time := 60 ns;
	
	function CLOCKS(t:time) return integer is
	variable r:integer;
	begin
		r := (tck + t - 1 fs)/tck;
		if r <= 1 then
			r := 2;
		end if;
		return r;
	end function;


	constant T_RP : natural := CLOCKS(trp);
	constant T_RC : natural := CLOCKS(trc);
	constant T_RSC: natural := 2;
	constant T_CAS: natural := 2;

	constant PCTR_MAX : natural := 200*(CLOCKSPEED/1000000);
	signal r_powerup_ctr : unsigned(numbits(PCTR_MAX) downto 0) := "0" & to_unsigned(PCTR_MAX, numbits(PCTR_MAX));

	type t_state_main is (
		powerup,
		config,
		run
	);

	signal r_state_main 	: 	t_state_main := powerup;

	type t_run_state is (
		idle
	);

	signal r_run_state 	: t_run_state := idle;

	-- used for substates in init/normal operations
	constant CYC_MAX : natural := 16;
	signal r_cycle			:	std_logic_vector(CYC_MAX downto 0);

	type sdram_cmd is record
		nCS	: std_logic;
		nRAS	: std_logic;
		nCAS	: std_logic;
		nWE	: std_logic;
	end record sdram_cmd;

	constant cmd_nop			: sdram_cmd := (nCS => '1', nRAS => '1', nCAS => '1', nWE => '1');
	constant cmd_setmode		: sdram_cmd := (nCS => '0', nRAS => '0', nCAS => '0', nWE => '0');
	constant cmd_bankact		: sdram_cmd := (nCS => '0', nRAS => '0', nCAS => '1', nWE => '1');
	constant cmd_write		: sdram_cmd := (nCS => '0', nRAS => '1', nCAS => '0', nWE => '0');
	constant cmd_read			: sdram_cmd := (nCS => '0', nRAS => '1', nCAS => '0', nWE => '1');
	constant cmd_autorefresh: sdram_cmd := (nCS => '0', nRAS => '0', nCAS => '0', nWE => '1');
	constant cmd_precharge	: sdram_cmd := (nCS => '0', nRAS => '0', nCAS => '1', nWE => '0');

	constant MODREG			: std_logic_vector(10 downto 0) := "00000" & std_logic_vector(to_unsigned(T_CAS,2)) & "0000"; --Burst=1, Seq, Cas=3

	signal	r_cmd		: sdram_cmd;

begin

	ctl_busy_o		<= '1' when r_state_main /= run else
							'1' when r_run_state /= idle else
							'0';

	sdram_CKE_o 	<= '1';
	sdram_nCS_o 	<= r_cmd.nCS;
	sdram_nRAS_o 	<= r_cmd.nRAS;
	sdram_nCAS_o 	<= r_cmd.nCAS;
	sdram_nWE_o 	<= r_cmd.nWE;

	p_state:process(clk)
		procedure RESET_CYCLE is
		begin
			r_cycle <= (0 => '1', others => '0');
		end RESET_CYCLE;
	begin

		if falling_edge(clk) then
			r_cycle <= r_cycle(r_cycle'high-1 downto 0) & '0';

			r_cmd <= cmd_nop;

			case r_state_main is 
				when powerup =>
					if r_powerup_ctr(r_powerup_ctr'high) = '1' then
						r_state_main <= config;
						RESET_CYCLE;
					end if;
				when config =>
					if r_cycle(0) = '1' then
						r_cmd <= cmd_precharge;
						sdram_A_o(10) <= '1';
						sdram_BS_o <= (others => '0');
					end if;
					if r_cycle(T_RP) = '1' then
						r_cmd <= cmd_autorefresh;
						sdram_A_o(10) <= '1';
						sdram_BS_o <= (others => '0');
					end if;
					if r_cycle(T_RP + T_RC) = '1' then
						r_cmd <= cmd_autorefresh;
						sdram_A_o(10) <= '1';
						sdram_BS_o <= (others => '0');
					end if;
					if r_cycle(T_RP + T_RC + T_RC) = '1' then
						r_cmd <= cmd_setmode;
						sdram_A_o <= (10 downto 0 => MODREG, others => '0');
						sdram_BS_o <= (others => '0');
					end if;
					if r_cycle(T_RP + T_RC + T_RC + T_RSC) = '1' then
						r_state_main <= run;
						r_run_state <= idle;
						RESET_CYCLE;
					end if;
				when others => null;


			end case;
		end if;

	end process;


	p_powerup:process(clk)
	begin
		if falling_edge(clk) then
			if r_powerup_ctr(r_powerup_ctr'high) = '0' then
				r_powerup_ctr <= r_powerup_ctr - 1;
			end if;
		end if;		
	end process;

end rtl;

