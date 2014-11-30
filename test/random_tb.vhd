library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_simUtils_pkg.all;
use work.rvex_simUtils_asDisas_pkg.all;

entity random_tb is
end random_tb;

architecture behavioral of random_tb is
  signal imem       : rvsp_assembledProgram_type;
  signal disas      : rvex_string_type;
begin
  
  test: process is
    variable imem_v : rvsp_assembledProgram_type;
    variable ok_v   : boolean;
  begin
    
    assemble(
      source => (
        -- 0x00000000
        "nop                                                                   ",
        "nop                                                                   ",
        "addcg r0.3, b0.4 = b0.5, r0.6, r0.63                                  ",
        "nop                                                                   ",
        "nop                                                                   ",
        "nop                                                                   ",
        "ldb r0.33 = 42[r0.0]                                                  ",
        "nop ;;                                                                ",

        -- 0x00000020
        "nop                                                                   ",
        "nop                                                                   ",
        "nop                                                                   ",
        "nop                                                                   ",
        "nop                                                                   ",
        "nop                                                                   ",
        "stb 33[r0.0] = r0.33                                                  ",
        "goto -0x40 ;;                                                         "
      ),
      imem => imem_v,
      ok => ok_v
    );
    imem <= imem_v;
    
    for i in 0 to 15 loop
      report integer'image(i) & ": " & rvs2str(disassemble(imem_v(i))) severity warning;
    end loop;
    
    wait;
  end process;
  
end behavioral;

