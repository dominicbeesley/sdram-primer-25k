library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use std.textio.all;

library work;
use work.fishbone.all;

entity top is
	generic(
		ROMFILE				: string := "C:\\Users\\Dominic\\Documents\\GitHub\\sdram-primer-25k\\src\\gowin\\6502tester\\asm\\build\\mos\\mos.mi";
		SIM					: boolean := FALSE;
		CLOCKSPEED			: natural := 50
		);
	port(
		rst_i					: in		std_logic;		-- reset from board
		clk_50_i				: in		std_logic;		-- 50 MHz clock from on board crystal

		uart_tx_o			: out		std_logic;		-- debug console output		

		led7_bits			: out		std_logic_vector(6 downto 0);
		led7_sel				: out		std_logic;

		dummy					: out		std_logic_vector(7 downto 0)

	);
end top;

architecture rtl of top is

	signal	i_cpu_clk	:	std_logic;

	constant MOS_SIZE : natural := 4096;

	type t_rom_type is array(0 to MOS_SIZE-1) of std_logic_vector(7 downto 0);

	impure function init_ram_hex(SIZE:natural) return t_rom_type is
	  file text_file : text open read_mode is ROMFILE;
	  variable text_line : line;
	  variable ram_content : t_rom_type;
	begin
	  for i in 0 to SIZE - 1 loop
	    readline(text_file, text_line);
	    hread(text_line, ram_content(i));
	  end loop;
	  
	  return ram_content;
	end function;

	signal	r_mos_rom	:	t_rom_type := init_ram_hex(MOS_SIZE);

	signal	x				:	unsigned(27 downto 0) := (others => '0');


	signal	r_debug_val	:	std_logic_vector(7 downto 0) := x"FA";

	signal	i_fbsyscon			:	fb_syscon_t;
	signal 	i_fb_cpu_c2p		:	fb_con_o_per_i_t;
	signal 	i_fb_cpu_p2c		:	fb_con_i_per_o_t;

	signal	i_debug_state		: std_logic_vector(2 downto 0);
begin

	dummy <= i_fb_cpu_c2p.A(7 downto 0);

	p_chk:process(clk_50_i)
	begin
		if rising_edge(clk_50_i) then
			x <= x + 1;
		end if;
	end process;

	i_fb_cpu_p2c.stall <= '0';
	i_fb_cpu_p2c.rdy <= '1';

	p_rom:process(i_fbsyscon)
	begin
		if rising_edge(i_fbsyscon.clk) then
			i_fb_cpu_p2c.D_rd <= r_mos_rom(to_integer(unsigned(i_fb_cpu_c2p.A(11 downto 0))));
			i_fb_cpu_p2c.ack <= i_fb_cpu_c2p.cyc and i_fb_cpu_c2p.a_stb;
		end if;
	end process;

	
	e_fb_sycon:entity work.fb_syscon
		generic map(
		SIM			=> SIM,
		CLOCKSPEED	=> CLOCKSPEED
	)
	port map(
		EXT_nRESET_i		=> not rst_i,
		clk_fish_i			=> clk_50_i,
		clk_lock_i			=> '1',
		sys_dll_lock_i		=> '1',
		fb_syscon_o			=> i_fbsyscon
	);
	
	e_cpu:entity work.fb_65c02
	generic map (
		SIM			=> SIM,
		CLOCKSPEED	=> CLOCKSPEED
	)
	port map (

		-- direct CPU control signals from system
		nmi_n_i		=> '1',
		irq_n_i		=> '1',

		-- fishbone signals
		fb_syscon_i	=> i_fbsyscon,
		fb_c2p_o		=> i_fb_cpu_c2p,
		fb_p2c_i		=>	i_fb_cpu_p2c,

		debug_state_o => i_debug_state
	);

	
	
	p_debug_lat:process(i_fbsyscon)
	begin
		 	if rising_edge(i_fbsyscon.clk) then
				if i_fb_cpu_c2p.d_wr_stb = '1' and i_fb_cpu_c2p.cyc = '1' and i_fb_cpu_c2p.we = '1' then
					r_debug_val <= i_fb_cpu_c2p.d_wr;
				end if;			
--				r_debug_val <= i_fb_cpu_c2p.A(7 downto 0);
--				r_debug_val <= 
--						i_fb_cpu_c2p.cyc 
--					& 	i_fb_cpu_c2p.a_stb 
--					& 	i_fbsyscon.rst
--					& 	i_fb_cpu_p2c.stall 
--					&  i_fb_cpu_p2c.ack
--					&  i_debug_state;
	 	end if;

	end process;


	e_fb_uart:entity work.fb_uart
	generic map (
		SIM			=> SIM,
		CLOCKSPEED	=> CLOCKSPEED,
		BAUDRATE		=> 19200
	)
	port map (

		-- fishbone signals
		fb_syscon_i	=> i_fbsyscon,
		fb_c2p_i		=> i_fb_cpu_c2p,
		fb_p2c_o		=>	open,

		-- serial
		tx_o			=> uart_tx_o
	);



	p_debug_leds:process(clk_50_i)
	variable v_clock_div : unsigned(19 downto 0);
	variable v_sel	: boolean;
	variable v_lat : std_logic_vector(7 downto 0);
		function BITS7(x:std_logic_vector(3 downto 0)) return std_logic_vector is	
		variable r : std_logic_vector(6 downto 0);
		begin
			case x is
				when "0000" => r := "1000000";
				when "0001" => r := "1111001";
				when "0010" => r := "0100100";
				when "0011" => r := "0110000";
				when "0100" => r := "0011001";
				when "0101" => r := "0010010";
				when "0110" => r := "0000010";
				when "0111" => r := "1111000";
				when "1000" => r := "0000000";
				when "1001" => r := "0011000";
				when "1010" => r := "0001000";
				when "1011" => r := "0000011";
				when "1100" => r := "0100111";
				when "1101" => r := "0100001";
				when "1110" => r := "0000110";
				when "1111" => r := "0001110";
				when others => r := "1111111";
			end case;
			return r;
		end function BITS7;
	begin
		if rising_edge(clk_50_i) then

			if v_sel then
				led7_sel <= '1';
				led7_bits <= BITS7(v_lat(3 downto 0));
			else				
				led7_sel <= '0';
				led7_bits <= BITS7(v_lat(7 downto 4));
			end if;



			if v_clock_div(v_clock_div'high) = '1' then
				v_clock_div := to_unsigned(524283, v_clock_div'length);
				if v_sel then
					v_lat := r_debug_val;
				end if;
				v_sel := not v_sel;
			else
				v_clock_div := v_clock_div - 1;					
			end if;

		end if;
	end process;

end rtl;
