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
  signal syllable   : rvex_syllable_type;
  signal ok         : boolean;
  signal charsValid : natural;
  signal error      : rvex_string_type;
begin
  
  test: process is
    variable syllable_v   : rvex_syllable_type;
    variable ok_v         : boolean;
    variable charsValid_v : natural;
    variable error_v      : rvex_string_builder_type;
  begin
    
    syllable_v := (others => '0');
    asAttempt(
      "add r#.3 = r#.4, r#.5",
      "add r#.%r1 = r#.%r2, r#.%r3",
      syllable_v, ok_v, charsValid_v, error_v
    );
    syllable   <= syllable_v;
    ok         <= ok_v;
    charsValid <= charsValid_v;
    error      <= rvs2sim(error_v);
    
    wait;
  end process;
  
end behavioral;

