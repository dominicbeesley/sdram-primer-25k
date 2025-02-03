-- MIT License
-- 
-- Copyright (c) 2024 dominicbeesley
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.




library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.math_real.all;

-- A signal naming wrapper between the generic test bench and the KM432S2030

library work;


entity sdram_wrap is
port (
      Dq       :  inout std_logic_vector(31 downto 0);
      Addr     :  in    std_logic_vector(11 downto 0); 
      Bs       :  in    std_logic_vector(1 downto 0); 
      Clk      :  in    std_logic; 
      Cke      :  in    std_logic;
      Cs_n     :  in    std_logic;
      Ras_n    :  in    std_logic;
      Cas_n    :  in    std_logic;
      We_n     :  in    std_logic;
      Dqm      :  in    std_logic_vector(3 downto 0)
   );
end sdram_wrap;


architecture rtl of sdram_wrap is


begin

   e_dut:entity work.mt48lc4m32b2 
    PORT MAP (
        BA0             => Bs(0),
        BA1             => Bs(1),
        DQM0            => Dqm(0),
        DQM1            => Dqm(1),
        DQM2            => Dqm(2),
        DQM3            => Dqm(3),
        DQ0             => Dq(0),
        DQ1             => Dq(1),
        DQ2             => Dq(2),
        DQ3             => Dq(3),
        DQ4             => Dq(4),
        DQ5             => Dq(5),
        DQ6             => Dq(6),
        DQ7             => Dq(7),
        DQ8             => Dq(8),
        DQ9             => Dq(9),
        DQ10            => Dq(10),
        DQ11            => Dq(11),
        DQ12            => Dq(12),
        DQ13            => Dq(13),
        DQ14            => Dq(14),
        DQ15            => Dq(15),
        DQ16            => Dq(16),
        DQ17            => Dq(17),
        DQ18            => Dq(18),
        DQ19            => Dq(19),
        DQ20            => Dq(20),
        DQ21            => Dq(21),
        DQ22            => Dq(22),
        DQ23            => Dq(23),
        DQ24            => Dq(24),
        DQ25            => Dq(25),
        DQ26            => Dq(26),
        DQ27            => Dq(27),
        DQ28            => Dq(28),
        DQ29            => Dq(29),
        DQ30            => Dq(30),
        DQ31            => Dq(31),
        CLK             => Clk,
        CKE             => Cke,
        A0              => Addr(0),
        A1              => Addr(1),
        A2              => Addr(2),
        A3              => Addr(3),
        A4              => Addr(4),
        A5              => Addr(5),
        A6              => Addr(6),
        A7              => Addr(7),
        A8              => Addr(8),
        A9              => Addr(9),
        A10             => Addr(10),
        A11             => Addr(11),
        WENeg           => We_n,
        RASNeg          => Ras_n,
        CSNeg           => Cs_n,
        CASNeg          => Cas_n
    );

end rtl;