-- MIT License
-- -----------------------------------------------------------------------------
-- Copyright (c) 2024 Dominic Beesley https://github.com/dominicbeesley
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
-- ----------------------------------------------------------------------

-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	22/05/2024
-- Design Name: 
-- Module Name:    	fb_sdram
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 		fishbone bus - a wrapper for the sdram controller
-- Dependencies: 
--
-- Revision: 
-- Additional Comments: 
--
----------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.fishbone.all;
use work.common.all;

entity fb_sdram is
	generic (
		SIM								: boolean := false;							-- skip some stuff, i.e. slow sdram start up
		CLOCKSPEED						: natural;										-- fast clock speed in mhz						
		T_CAS_EXTRA 					: natural := 0	-- this neads to be 1 for > ~90 MHz
	);
	port(

		-- fishbone signals
		fb_syscon_i						: in 	fb_syscon_t;
		fb_c2p_i							: in 	fb_con_o_per_i_t;
		fb_p2c_o							: out fb_con_i_per_o_t;

		-- sdram interface
		sdram_clk_o			:  out	std_logic;
		sdram_DQ_io			:	inout std_logic_vector(15 downto 0);
		sdram_A_o			:	out	std_logic_vector(12 downto 0); 
		sdram_BS_o			:  out 	std_logic_vector(1 downto 0); 
		sdram_CKE_o			:	out	std_logic;
		sdram_nCS_o			:	out	std_logic;
		sdram_nRAS_o		:	out	std_logic;
		sdram_nCAS_o		:	out	std_logic;
		sdram_nWE_o			:	out	std_logic;
		sdram_DQM_o			:	out	std_logic_vector(1 downto 0);

		ctl_reset_i			:	in		std_logic


	);
end fb_sdram;

architecture rtl of fb_sdram is

	signal 	i_ctl_stall			:	std_logic;
	signal 	i_ctl_cyc			:	std_logic;
	signal 	i_ctl_we				:	std_logic;
	signal 	i_ctl_A				:	std_logic_vector(24 downto 0);
	signal 	i_ctl_D_wr			:	std_logic_vector(7 downto 0);
	signal 	i_ctl_D_rd			:	std_logic_vector(7 downto 0);
	signal 	i_ctl_ack			:	std_logic;

	type t_state is (idle, rd, wr, wr_wait);
	signal 	r_state				: 	t_state;
	signal	r_ack					:  std_logic;
	signal	r_rdy					:  std_logic;
	
	signal	i_sdram_clk			: std_logic;

begin

	i_sdram_clk <= fb_syscon_i.clk;

	sdram_clk_o <= i_sdram_clk;

	fb_p2c_o.rdy <= r_rdy;
	fb_p2c_o.ack <= r_ack;
	fb_p2c_o.stall <= '0' when r_state = idle else
							'1';

	p_fb:process(fb_syscon_i)
	begin
		if fb_syscon_i.rst = '1' then
			r_state <= idle;
		elsif rising_edge(fb_syscon_i.clk) then

			r_ack <= '0';

			case r_state is
				when idle =>
					i_ctl_cyc <= '0';
					r_rdy <= '0';
					if fb_c2p_i.cyc = '1' and fb_c2p_i.A_stb = '1' then
						i_ctl_we 	<= fb_c2p_i.we;
						i_ctl_A  	<= "0" & fb_c2p_i.A;
						i_ctl_D_wr <= fb_c2p_i.D_wr;

						if fb_c2p_i.we = '1' and fb_c2p_i.D_wr_stb = '0' then
							r_state <= wr_wait;
						else
							i_ctl_cyc <= '1';
							if fb_c2p_i.we = '1' then
								r_state <= wr;
							else
								r_state <= rd;
							end if;
						end if;
					end if;
				when rd =>
					if i_ctl_ack = '1' then
						fb_p2c_o.D_rd <= i_ctl_D_rd;
						r_rdy <= '1';
						r_ack <= '1';
						r_state <= idle;						
						i_ctl_cyc <= '0';
					end if;
				when wr =>
					if i_ctl_ack = '1' then
						r_rdy <= '1';
						r_ack <= '1';
						r_state <= idle;						
						i_ctl_cyc <= '0';
					end if;
				when wr_wait =>
					if fb_c2p_i.D_wr_stb = '1' and i_ctl_stall = '0' then
						i_ctl_D_wr <= fb_c2p_i.D_wr;

					end if;
				when others =>
						i_ctl_cyc <= '0';
						r_rdy <= '1';
						r_ack <= '1';
						r_state <= idle;						
			end case;

		end if;
	end process;



	e_sdramctl:entity work.sdramctl
	generic map (
		CLOCKSPEED => CLOCKSPEED * 1000000,
		T_CAS_EXTRA	=> T_CAS_EXTRA
		)
	port map (
		Clk					=> i_sdram_clk,

	--A(0)		byte lane
	--A(1..9)	column address
	--A(10..22)	row address
	--A(23..24)	bank address


		-- sdram interface
		sdram_DQ_io			=> sdram_DQ_io,
		sdram_A_o			=> sdram_A_o,
		sdram_BS_o			=> sdram_BS_o,
		sdram_CKE_o			=> sdram_CKE_o,
		sdram_nCS_o			=> sdram_nCS_o,
		sdram_nRAS_o		=> sdram_nRAS_o,
		sdram_nCAS_o		=> sdram_nCAS_o,
		sdram_nWE_o			=> sdram_nWE_o,
		sdram_DQM_o			=> sdram_DQM_o,

		-- cpu interface

		ctl_rfsh_i			=> '1',
		ctl_reset_i			=> ctl_reset_i,
		ctl_stall_o			=> i_ctl_stall,
		ctl_cyc_i			=> i_ctl_cyc,
		ctl_we_i				=> i_ctl_we,
		ctl_A_i				=> i_ctl_A,
		ctl_D_wr_i			=> i_ctl_D_wr,
		ctl_D_rd_o			=> i_ctl_D_rd,
		ctl_ack_o			=> i_ctl_ack
	);

end rtl;