library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.rvex_pkg.all;
use work.rvex_simUtils_pkg.all;
use work.rvex_simUtils_asDisas_pkg.all;
use work.rvex_simUtils_mem_pkg.all;

entity random_tb is
end random_tb;

architecture behavioral of random_tb is
--  signal imem       : rvsp_assembledProgram_type;
--  signal disas      : rvex_string_type;
begin
  
--  test: process is
--    variable imem_v : rvsp_assembledProgram_type;
--    variable ok_v   : boolean;
--    variable test   : std_logic_vector(31 downto 0);
--  begin
--    
--    assemble(
--      source => (
--        -- 0x00000000
--        "nop                                                                   ",
--        "nop                                                                   ",
--        "addcg r0.3, b0.4 = b0.5, r0.6, r0.63                                  ",
--        "nop                                                                   ",
--        "nop                                                                   ",
--        "nop                                                                   ",
--        "ldb r0.33 = 42[r0.0]                                                  ",
--        "nop ;;                                                                ",
--
--        -- 0x00000020
--        "nop                                                                   ",
--        "nop                                                                   ",
--        "nop                                                                   ",
--        "nop                                                                   ",
--        "nop                                                                   ",
--        "nop                                                                   ",
--        "stb 33[r0.0] = r0.33                                                  ",
--        "goto -0x40 ;;                                                         "
--      ),
--      imem => imem_v,
--      ok => ok_v
--    );
--    imem <= imem_v;
--    
--    for i in 0 to 15 loop
--      report integer'image(i) & ": " & rvs2str(disassemble(imem_v(i))) severity warning;
--    end loop;
--    
--    test := X"76543210";
--    report "So will this give 3 or 0x3000? " & integer'image(to_integer(unsigned(test(15 downto 12)))) severity warning;
--    report "And this will give zero, right? " & integer'image(to_integer(unsigned(test(11 downto 12)))) severity warning;
--    for i in 1 to 5 loop
--      report "Will it keep spamming null range warnings? " & integer'image(to_integer(unsigned(test(11 downto 12)))) severity warning;
--    end loop;
--    for i in 1 to 5 loop
--      if true or to_integer(unsigned(test(11 downto 12))) = 1 then
--        report "Will it at least not spam null range warnings here?" severity warning;
--      end if;
--    end loop;
--    for i in 1 to 5 loop
--      if to_integer(unsigned(test(11 downto 12))) = 1 or true then
--        report "And it will here?" severity warning;
--      end if;
--    end loop;
--    report "So at least lazy evaluation is a thing. Note to self: add checks all over the place to prevent massive spam in static core designs." severity failure;
--    
--    wait;
--  end process;
  
--  more_tests: process is
--    file f : text;
--    variable l : line;
--  begin
--    file_open(f, "../readme.txt", read_mode);
--    while not endfile(f) loop
--      readline(f, l);
--      report "I read: " & l.all severity note;
--    end loop;
--    file_close(f);
--    wait;
--  end process;
  
  memtest: process is
    variable mem          : rvmem_memoryState_type;
    variable seed1, seed2 : positive;
    variable addr         : rvex_address_type;
    variable val          : rvex_data_type;
    variable readval      : rvex_data_type;
  begin
    
    -- Clear the memory.
    rvmem_clear(mem);
    
    -- Perform random (but repeatable) writes to the memory.
    seed1 := 1;
    seed2 := 1;
    for i in 1 to 1024 loop
      rvs_randomVect(seed1, seed2, addr);
      rvs_randomVect(seed1, seed2, val);
      rvmem_write(mem, addr, val);
    end loop;
    
    -- Now perform the same random accesses and verify that the memory returns
    -- the correct value.
    seed1 := 1;
    seed2 := 1;
    for i in 1 to 1024 loop
      rvs_randomVect(seed1, seed2, addr);
      rvs_randomVect(seed1, seed2, val);
      readval := rvmem_read(mem, addr);
      if readval /= val then
        report "Inconsistency: addr " & rvs_hex(addr, 8) & " should "
             & "be " & rvs_hex(val, 8) & " bus was "
             & rvs_hex(readval, 8)
          severity failure;
        wait;
      end if;
    end loop;
    
    report "Memory seems to be sane!" severity note;
    
    -- Try to load an srec file.
    rvmem_clear(mem);
    rvmem_loadSRec(mem, "../test/from_wikipedia.srec");
    rvmem_dumpSRec(mem, "../test/output.srec");
    rvmem_dump(mem, "../test/output.txt");
    
    wait;
    
  end process;
  
end behavioral;

