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

-- A signal naming wrapper between the generic test bench and the W9825G6KH

library work;


entity sdram_wrap is
port (
      Dq       :  inout std_logic_vector(15 downto 0);
      Addr     :  in    std_logic_vector(12 downto 0); 
      Bs       :  in    std_logic_vector(1 downto 0); 
      Clk      :  in    std_logic; 
      Cke      :  in    std_logic;
      Cs_n     :  in    std_logic;
      Ras_n    :  in    std_logic;
      Cas_n    :  in    std_logic;
      We_n     :  in    std_logic;
      Dqm      :  in    std_logic_vector(1 downto 0)
   );
end sdram_wrap;


architecture rtl of sdram_wrap is

   component W9825G6KH port (
      Dq       :  inout std_logic_vector(15 downto 0);
      Addr     :  in    std_logic_vector(12 downto 0); 
      Bs       :  in    std_logic_vector(1 downto 0); 
      Clk      :  in    std_logic; 
      Cke      :  in    std_logic;
      Cs_n     :  in    std_logic;
      Ras_n    :  in    std_logic;
      Cas_n    :  in    std_logic;
      We_n     :  in    std_logic;
      Dqm      :  in    std_logic_vector(1 downto 0)
   );
   end component;

begin

   e_dut:W9825G6KH
   port map (
      Dq       => Dq,
      Addr     => Addr,
      Bs       => Bs,
      Clk      => Clk,
      Cke      => Cke,
      Cs_n     => Cs_n,
      Ras_n    => Ras_n,
      Cas_n    => Cas_n,
      We_n     => We_n,
      Dqm      => Dqm
   );

end rtl;