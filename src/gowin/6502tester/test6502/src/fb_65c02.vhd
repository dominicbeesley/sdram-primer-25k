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

entity fb_65c02 is
	generic (
		SIM									: boolean := false;							-- skip some stuff, i.e. slow sdram start up
		CLOCKSPEED							: natural										-- fast clock speed in mhz						
	);
	port(

		-- direct CPU control signals from system
		nmi_n_i									: in	std_logic;
		irq_n_i									: in	std_logic;

		-- fishbone signals
		fb_syscon_i								: in	fb_syscon_t;
		fb_c2p_o									: out fb_con_o_per_i_t;
		fb_p2c_i									: in	fb_con_i_per_o_t;

		debug_state_o							: out	std_logic_vector(2 downto 0)

	);
end fb_65c02;

architecture rtl of fb_65c02 is
	signal	i_cpu_cken		: 	std_logic;
	signal	i_cpu_D_i		:	unsigned(7 downto 0);
	signal	i_cpu_D_o		:	unsigned(7 downto 0);
	signal	i_cpu_A			:	unsigned(15 downto 0);
	signal	i_cpu_rnw		:	std_logic;

	type t_state is (phi1, phi1_2, phi1_3, phi2);

	signal	r_state			:	t_state := phi1;
	signal  	r_had_ack		:  std_logic;

begin

	debug_state_o	<= "000" when r_state = phi1 else
							"011" when r_state = phi1_2 else
							"010" when r_state = phi1_3 else
							"011" when r_state = phi2 else
							"111" ;

	p_state:process(fb_syscon_i)
	variable p_rst : std_logic := '0';
	begin
		if rising_edge(fb_syscon_i.clk) then
			if p_rst = '0' and fb_syscon_i.rst = '1' then
				r_state <= phi1;
			else

				i_cpu_cken <= '0';

				case r_state is 
					when phi1 => 
						r_state <= phi1_2;
					when phi1_2 =>
						fb_c2p_o <= (
							cyc => '1',
							we => not i_cpu_rnw,
							A => x"FF" & std_logic_vector(i_cpu_A),
							a_stb => '1',
							D_wr => std_logic_vector(i_cpu_D_o),
							D_wr_stb => '1',
							rdy_ctdn => RDY_CTDN_MIN
							);
						r_state <= phi1_3;
					when phi1_3 => 
						if fb_p2c_i.stall = '0' or fb_syscon_i.rst = '1' then
							fb_c2p_o.a_stb <= '0';
							r_state <= phi2;
							r_had_ack <= fb_p2c_i.ack;
							if fb_p2c_i.ack = '1' then
								i_cpu_D_i <= unsigned(fb_p2c_i.D_rd);
							end if;
						end if;
					when phi2 =>
						if r_had_ack = '1' then
							i_cpu_cken <= '1';
							fb_c2p_o.cyc <= '0';
							r_state <= phi1;
						elsif fb_p2c_i.ack = '1' or fb_syscon_i.rst = '1' then
							i_cpu_D_i <= unsigned(fb_p2c_i.D_rd);
							i_cpu_cken <= '1';
							fb_c2p_o.cyc <= '0';
							r_state <= phi1;
						end if;
					when others => null;
						r_state <= phi1;
				end case;

			end if;
			p_rst := fb_syscon_i.rst;
		end if;

	end process;


	e_cpu:entity work.R65C02
	port map (
        reset    => not fb_syscon_i.rst,
        clk      => fb_syscon_i.clk,
        enable   => i_cpu_cken,
        nmi_n    => nmi_n_i,
        irq_n    => irq_n_i,
        di       => i_cpu_D_i,
        do       => i_cpu_D_o,
        addr     => i_cpu_A,
        nwe      => i_cpu_rnw,
        sync     => open,
        sync_irq => open,
        -- 6502 registers (MSB) PC, SP, P, Y, X, A (LSB)
        Regs     => open
	);

end rtl;