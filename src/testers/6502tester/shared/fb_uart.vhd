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
-- Create Date:    	20/05/2024
-- Design Name: 
-- Module Name:    	fb_65c02
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 		fishbone bus - 65c02 CPU wrapper component for AlanD core
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

entity fb_uart is
	generic (
		SIM								: boolean := false;							-- skip some stuff, i.e. slow sdram start up
		CLOCKSPEED						: natural;										-- fast clock speed in mhz						
		BAUDRATE							: natural
	);
	port(

		-- fishbone signals
		fb_syscon_i						: in 	fb_syscon_t;
		fb_c2p_i							: in 	fb_con_o_per_i_t;
		fb_p2c_o							: out fb_con_i_per_o_t;

		-- serial
		tx_o								: out std_logic
	);
end fb_uart;

architecture rtl of fb_uart is
	
	constant BDIV 				: natural := CLOCKSPEED * 1000000 / BAUDRATE;

	signal 	r_baud_clk_div	: unsigned(numbits(BDIV) downto 0)	:= to_unsigned(BDIV-1, numbits(BDIV)+1);
	signal	r_baud_clken	: std_logic;

	signal	r_bit_ix			: unsigned(3 downto 0)				:= (others => '0');
	signal	r_sr				: std_logic_vector(9 downto 0)	:= (others => '1');

	signal	r_req				: std_logic								:= '0';
	signal	r_ack				: std_logic								:= '0';
	signal	r_dat				: std_logic_vector(7 downto 0)	:= (others => '0');

begin
	

	fb_p2c_o.rdy <= '1';
	fb_p2c_o.stall <= '0';
	fb_p2c_o.D_rd <= (7 => r_req xor r_ack, others => '1');

	p_fb:process(fb_syscon_i)
	variable v_we : std_logic;
	variable v_cyc: std_logic;
	begin
		if fb_syscon_i.rst = '1' then
			r_req <= '0';
			r_dat <= (others => '0');
			v_we := '0';
			v_cyc := '0';
		elsif rising_edge(fb_syscon_i.clk) then
			if fb_c2p_i.cyc = '1' and fb_c2p_i.a_stb = '1' then
				v_cyc := '1';
				v_we := fb_c2p_i.we;
			end if;

			if v_cyc then
				if v_we = '0' then
					fb_p2c_o.ack <= '1';
					v_cyc := '0';
				elsif v_we = '1' and fb_c2p_i.d_wr_stb = '1' then
					fb_p2c_o.ack <= '1';
					r_dat <= fb_c2p_i.d_wr;
					r_req <= not r_ack;
					v_cyc := '0';
				end if;
			end if;
		end if;
	end process;

	p_baud_gen:process(fb_syscon_i)
	begin
		if fb_syscon_i.rst = '1' then
			r_baud_clken <= '0';
			r_baud_clk_div <= to_unsigned(BDIV-1, r_baud_clk_div'length);
		elsif rising_edge(fb_syscon_i.clk) then
			r_baud_clken <= '0';
	
			if r_baud_clk_div(r_baud_clk_div'high) = '1' then
				r_baud_clk_div <= to_unsigned(BDIV-1, r_baud_clk_div'length);
				r_baud_clken <= '1';
			else
				r_baud_clk_div <= r_baud_clk_div - 1;
			end if;
		end if;
	end process;

	b_bit_send:process(fb_syscon_i)
	begin

		if fb_syscon_i.rst = '1' then
			r_bit_ix <= (others => '0');
			r_sr <= (others => '1');
			r_ack <= '0';
		elsif rising_edge(fb_syscon_i.clk) then
			if r_baud_clken = '1' then
					
				if r_bit_ix = 0 then
					if r_req /= r_ack then
						r_bit_ix <= to_unsigned(9, r_bit_ix'length);
						r_sr <= "1" & r_dat & "0";
						r_ack <= r_req;
					end if;
				else					
					r_sr <= "1" & r_sr(9 downto 1);
					r_bit_ix <= r_bit_ix - 1;
				end if;

			end if;
		end if;
	end process;

	tx_o <= r_sr(0);

end rtl;