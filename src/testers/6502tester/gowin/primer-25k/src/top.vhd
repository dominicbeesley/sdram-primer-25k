library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use std.textio.all;

library work;
use work.common.all;
use work.fishbone.all;


-- Test the SDRAM on a Primer 25K expects:
-- with Primer oriented with PMODS at "top", usb left, hdmi right
-- SDRAM "pmod" in SDRAM header
-- PMOD_LEDx8 in right socket
-- POMD_DTx2 in middle socket


entity top is
	generic(
		ROMFILE				: string := "../../asm/build/tester-primer-25k/mos.mi";
		SIM					: boolean := FALSE;
		CLOCKSPEED			: natural := 125;
		T_CAS_EXTRA 		: natural := 1;

		-- SDRAM geometry
		LANEBITS		: natural 	:= 1;	-- number of byte lanes bits, if 0 don't connect sdram_DQM_o
		BANKBITS    : natural 	:= 2;	-- number of bits, if none set to 0 and don't connect sdram_BS_o
		ROWBITS     : positive 	:= 13;
		COLBITS		: positive 	:= 9;

		-- SDRAM speed
		trp 			: time := 15 ns;  -- precharge
		trcd 			: time := 15 ns;	-- active to read/write
		trc 			: time := 60 ns;	-- active to active time
		trfsh			: time := 1.8 us;	-- the refresh control signal will be blocked if it occurs more frequently than this
		trfc  		: time := 63 ns 	-- refresh cycle time

		);
	port(
		rst_i					: in		std_logic;		-- reset from board
		clk_50_i				: in		std_logic;		-- 50 MHz clock from on board crystal

		uart_tx_o			: out		std_logic;		-- debug console output		

		led7_bits			: out		std_logic_vector(6 downto 0);
		led7_sel				: out		std_logic;

		leds_o				: out		std_logic_vector(7 downto 0);

		-- sdram interface
		sdram_clk_o			:  out	std_logic;
		sdram_DQ_io			:	inout std_logic_vector((2**LANEBITS)*8-1 downto 0);
		sdram_A_o			:	out	std_logic_vector(maximum(COLBITS, ROWBITS)-1 downto 0); 
		sdram_BS_o			:  out 	std_logic_vector(maximum(BANKBITS-1, 0) downto 0); 
		sdram_CKE_o			:	out	std_logic;
		sdram_nCS_o			:	out	std_logic;
		sdram_nRAS_o		:	out	std_logic;
		sdram_nCAS_o		:	out	std_logic;
		sdram_nWE_o			:	out	std_logic;
		sdram_DQM_o			:	out	std_logic_vector(2 ** LANEBITS - 1 downto 0)

	);
end top;

architecture rtl of top is


	signal   i_lock_pll	: std_logic;
	signal   i_clk_pll	: std_logic;
	signal   i_clk_pll_p	: std_logic;

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

	signal	r_ram			:	t_rom_type;


	signal	i_led7_val			:	std_logic_vector(7 downto 0) := x"FA";

	signal	i_fbsyscon			:	fb_syscon_t;
	signal 	i_fb_cpu_c2p		:	fb_con_o_per_i_t;
	signal 	i_fb_cpu_p2c		:	fb_con_i_per_o_t;

	signal	i_debug_state		: std_logic_vector(2 downto 0);

	constant C_PERIPHERAL_COUNT 	:	natural := 6;

	signal   i_fb_per_c2p			:	fb_con_o_per_i_arr(C_PERIPHERAL_COUNT-1 downto 0);
	signal   i_fb_per_p2c			:	fb_con_i_per_o_arr(C_PERIPHERAL_COUNT-1 downto 0);
	constant C_PER_MOS				:	natural := 0;
	signal 	i_fb_mos_c2p			:	fb_con_o_per_i_t;
	signal 	i_fb_mos_p2c			:	fb_con_i_per_o_t;
	constant C_PER_LED7				:	natural := 1;
	signal 	i_fb_led7_c2p			:	fb_con_o_per_i_t;
	signal 	i_fb_led7_p2c			:	fb_con_i_per_o_t;
	constant C_PER_UART				:	natural := 2;
	signal 	i_fb_uart_c2p			:	fb_con_o_per_i_t;
	signal 	i_fb_uart_p2c			:	fb_con_i_per_o_t;
	constant C_PER_RAM				:	natural := 3;
	signal 	i_fb_ram_c2p			:	fb_con_o_per_i_t;
	signal 	i_fb_ram_p2c			:	fb_con_i_per_o_t;
	constant C_PER_PORTA				:	natural := 4;
	signal 	i_fb_porta_c2p			:	fb_con_o_per_i_t;
	signal 	i_fb_porta_p2c			:	fb_con_i_per_o_t;
	constant C_PER_SDRAM				:	natural := 5;
	signal 	i_fb_sdram_c2p			:	fb_con_o_per_i_t;
	signal 	i_fb_sdram_p2c			:	fb_con_i_per_o_t;

	signal	i_cpu_sel_addr			:	std_logic_vector(23 downto 0);
	signal	i_cpu_sel				:	unsigned(numbits(C_PERIPHERAL_COUNT)-1 downto 0);
	signal	i_cpu_sel_oh			:	std_logic_vector(C_PERIPHERAL_COUNT-1 downto 0);

	signal	i_porta_o_bits			:  std_logic_vector(7 downto 0);

	signal	r_pll_reset				:	std_logic;
	signal	r_pll_reset_prev		:	std_logic	:= '0';
	signal	r_pll_reset_ctr		:	unsigned(1 downto 0) := (others => '0');

begin

	p_rom:process(i_fbsyscon)
	begin
		if rising_edge(i_fbsyscon.clk) then
			i_fb_mos_p2c.D_rd <= r_mos_rom(to_integer(unsigned(i_fb_mos_c2p.A(11 downto 0))));
			i_fb_mos_p2c.ack <= i_fb_cpu_c2p.cyc and i_fb_mos_c2p.a_stb;
		end if;
	end process;
	i_fb_mos_p2c.stall <= '0';
	i_fb_mos_p2c.rdy <= '1';

	p_ram:process(i_fbsyscon)
	variable v_we : std_logic;
	variable v_we_addr : std_logic_vector(11 downto 0);
	variable v_cyc: std_logic;
	begin
		if i_fbsyscon.rst = '1' then
			v_we := '0';
			v_cyc:= '0';		
		elsif rising_edge(i_fbsyscon.clk) then

			if i_fb_ram_c2p.cyc = '0' then
				v_we := '0';
				v_cyc:= '0';
			elsif i_fb_ram_c2p.cyc = '1' and i_fb_ram_c2p.a_stb = '1' then
				v_cyc:= '1';
				v_we := i_fb_ram_c2p.we;
				v_we_addr := i_fb_ram_c2p.A(11 downto 0);
			end if;

			i_fb_ram_p2c.D_rd <= r_ram(to_integer(unsigned(v_we_addr)));
			i_fb_ram_p2c.ack <= v_cyc and (not v_we or i_fb_ram_c2p.D_wr_stb);
			if v_cyc = '1' and v_we = '1' and i_fb_ram_c2p.D_wr_stb = '1' then
				r_ram(to_integer(unsigned(v_we_addr))) <= i_fb_ram_c2p.D_wr;
			end if;
		end if;
	end process;
	i_fb_ram_p2c.stall <= '0';
	i_fb_ram_p2c.rdy <= '1';

	
	e_fb_sycon:entity work.fb_syscon
		generic map(
		SIM			=> SIM,
		CLOCKSPEED	=> CLOCKSPEED
	)
	port map(
		EXT_nRESET_i		=> not rst_i,
		clk_fish_i			=> i_clk_pll,
		clk_lock_i			=> i_lock_pll,
		sys_dll_lock_i		=> '1',
		fb_syscon_o			=> i_fbsyscon
	);
	
	e_fb_mux:entity work.fb_intcon_one_to_many
	generic map(
		SIM					=> SIM,
		G_PERIPHERAL_COUNT	=> C_PERIPHERAL_COUNT,
		G_ADDRESS_WIDTH		=> 24
	)
	port map (

		fb_syscon_i			=> i_fbsyscon,

		-- peripheral port connect to controllers
		fb_con_c2p_i		=> i_fb_cpu_c2p,
		fb_con_p2c_o		=> i_fb_cpu_p2c,

		-- controller port connecto to peripherals
		fb_per_c2p_o		=> i_fb_per_c2p,
		fb_per_p2c_i		=> i_fb_per_p2c,

		-- peripheral select interface -- note, testing shows that having both one hot and index is faster _and_ uses fewer resources
		peripheral_sel_addr_o		=> i_cpu_sel_addr,
		peripheral_sel_i				=> i_cpu_sel,
		peripheral_sel_oh_i			=> i_cpu_sel_oh

	);

	i_fb_per_p2c(C_PER_MOS) 	<= i_fb_mos_p2c;
	i_fb_per_p2c(C_PER_LED7) 	<= i_fb_led7_p2c;
	i_fb_per_p2c(C_PER_UART) 	<= i_fb_uart_p2c;
	i_fb_per_p2c(C_PER_RAM) 	<= i_fb_ram_p2c;
	i_fb_per_p2c(C_PER_PORTA) 	<= i_fb_porta_p2c;
	i_fb_per_p2c(C_PER_SDRAM) 	<= i_fb_sdram_p2c;

	i_fb_mos_c2p					<= i_fb_per_c2p(C_PER_MOS);
	i_fb_led7_c2p					<= i_fb_per_c2p(C_PER_LED7);
	i_fb_uart_c2p					<= i_fb_per_c2p(C_PER_UART);
	i_fb_ram_c2p					<= i_fb_per_c2p(C_PER_RAM);
	i_fb_porta_c2p					<= i_fb_per_c2p(C_PER_PORTA);
	i_fb_sdram_c2p					<= i_fb_per_c2p(C_PER_SDRAM);

	p_sel:process(i_cpu_sel_addr)
	variable I:integer;
	begin
		I	:=	C_PER_PORTA	when i_cpu_sel_addr(15 downto 12) = x"C" else
				C_PER_UART	when i_cpu_sel_addr(15 downto 12) = x"D" else
				C_PER_LED7	when i_cpu_sel_addr(15 downto 12) = x"E" else
				C_PER_MOS	when i_cpu_sel_addr(15 downto 12) = x"F" else
				C_PER_RAM	when i_cpu_sel_addr(15 downto 12) = x"0" else
				C_PER_SDRAM;

		i_cpu_sel <= to_unsigned(I, i_cpu_sel'length);
				
		i_cpu_sel_oh <= (others => '0');
		i_cpu_sel_oh(I) <= '1';
	end process;


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

	e_fb_led7:entity work.fb_port_io
	generic map (
		SIM			=> SIM,
		CLOCKSPEED	=> CLOCKSPEED
	)
	port map (

		-- fishbone signals
		fb_syscon_i	=> i_fbsyscon,
		fb_c2p_i		=> i_fb_led7_c2p,
		fb_p2c_o		=>	i_fb_led7_p2c,

		-- port
		bits_o		=> i_led7_val,
		bits_i		=> (others => '1')
	);
	


	e_fb_uart:entity work.fb_uart
	generic map (
		SIM			=> SIM,
		CLOCKSPEED	=> CLOCKSPEED,
		BAUDRATE		=> 19200
	)
	port map (

		-- fishbone signals
		fb_syscon_i	=> i_fbsyscon,
		fb_c2p_i		=> i_fb_uart_c2p,
		fb_p2c_o		=>	i_fb_uart_p2c,

		-- serial
		tx_o			=> uart_tx_o
	);

	e_fb_porta:entity work.fb_port_io
	generic map (
		SIM			=> SIM,
		CLOCKSPEED	=> CLOCKSPEED
	)
	port map (

		-- fishbone signals
		fb_syscon_i	=> i_fbsyscon,
		fb_c2p_i		=> i_fb_porta_c2p,
		fb_p2c_o		=>	i_fb_porta_p2c,

		-- port
		bits_o		=> i_porta_o_bits,
		bits_i		=> (others => '1')
	);

	e_fb_sdram:entity work.fb_sdram
	generic map(
		SIM				=> SIM,
		CLOCKSPEED		=> CLOCKSPEED,
		T_CAS_EXTRA	=> T_CAS_EXTRA,
		LANEBITS		=> LANEBITS,
		BANKBITS		=> BANKBITS,
		ROWBITS		=> ROWBITS,
		COLBITS		=> COLBITS,
		trp			=> trp,
		trcd			=> trcd,
		trc			=> trc,
		trfsh			=> trfsh,
		trfc			=> trfc
	)
	port map (

		-- fishbone signals
		fb_syscon_i		=> i_fbsyscon,
		fb_c2p_i			=> i_fb_sdram_c2p,
		fb_p2c_o			=> i_fb_sdram_p2c,

		

		-- sdram interface
		sdram_DQ_io		=> sdram_DQ_io,
		sdram_A_o		=> sdram_A_o,
		sdram_BS_o		=> sdram_BS_o,
		sdram_CKE_o		=> sdram_CKE_o,
		sdram_nCS_o		=> sdram_nCS_o,
		sdram_nRAS_o	=> sdram_nRAS_o,
		sdram_nCAS_o	=> sdram_nCAS_o,
		sdram_nWE_o		=> sdram_nWE_o,
		sdram_DQM_o		=> sdram_DQM_o,

		ctl_reset_i		=> i_porta_o_bits(2),

		man_refresh_i  => '1'
	);

	sdram_clk_o		<= i_clk_pll_p;


	p_debug_leds:process(i_fbsyscon)
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
		if rising_edge(i_fbsyscon.clk) then

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
					v_lat := i_led7_val;
				end if;
				v_sel := not v_sel;
			else
				v_clock_div := v_clock_div - 1;					
			end if;

		end if;
	end process;

	leds_o <= not (i_debug_state & "1" & rst_i & i_fbsyscon.rst & i_porta_o_bits(1 downto 0));

	p_pll_reset:process(clk_50_i, rst_i)	
	begin

		if rising_edge(clk_50_i) then
			if r_pll_reset_prev = '0' and rst_i = '1' then
				r_pll_reset_ctr <= (others => '0');
			elsif r_pll_reset_ctr(r_pll_reset_ctr'high) = '0' then
				r_pll_reset_ctr <= r_pll_reset_ctr + 1;
			end if;

			r_pll_reset_prev <= rst_i;
			r_pll_reset <= not std_logic(r_pll_reset_ctr(r_pll_reset_ctr'high));
		end if;

	end process;

	e_pll1: entity work.pll1
   port map (
   	lock => i_lock_pll,
   	reset => r_pll_reset,
   	--reset => '0',
   	clkout0 => i_clk_pll,
   	clkout1 => i_clk_pll_p,
   	clkin => clk_50_i,
   	pssel => "001",
	  	psdir => i_porta_o_bits(1),
   	pspulse => i_porta_o_bits(0)
	);


end rtl;
