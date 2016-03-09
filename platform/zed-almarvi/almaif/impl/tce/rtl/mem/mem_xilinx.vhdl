-----------------
-- Dual-Port Block RAM with Two Write Ports
-- Correct Modelization with a Shared Variable
--
-- Download:
-- http://www.xilinx.com/txpatches/pub/documentation/misc/xstug_examples.zip
-- File: HDL_Coding_Techniques/rams/rams_16b.vhd
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity rams is
  generic (
    addr_width_g : integer := 16;
    data_width_g : integer := 32
  );
  port(
    clka : in std_logic;
    clkb : in std_logic;
    ena : in std_logic;
    enb : in std_logic;
    wea : in std_logic;
    web : in std_logic;
    addra : in std_logic_vector(addr_width_g-1 downto 0);
    addrb : in std_logic_vector(addr_width_g-1 downto 0);
    dia : in std_logic_vector(data_width_g-1 downto 0);
    dib : in std_logic_vector(data_width_g-1 downto 0);
    doa : out std_logic_vector(data_width_g-1 downto 0);
    dob : out std_logic_vector(data_width_g-1 downto 0)
  );
end rams;

architecture syn of rams is
  type ram_type is array (2**addr_width_g-1 downto 0)
    of std_logic_vector(data_width_g-1 downto 0);
  shared variable RAM : ram_type;
begin
  
  process (CLKA)
  begin
    if rising_edge(CLKA) then
      if ENA = '1' then
        DOA <= RAM(conv_integer(ADDRA));
        if WEA = '1' then
          RAM(conv_integer(ADDRA)) := DIA;
        end if;
      end if;
    end if;
  end process;
  
  process (CLKB)
  begin
    if rising_edge(CLKB) then
      if ENB = '1' then
        DOB <= RAM(conv_integer(ADDRB));
        if WEB = '1' then
          RAM(conv_integer(ADDRB)) := DIB;
        end if;
      end if;
    end if;
  end process;
  
end syn;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity rams_be is
  generic (
    addr_width_g : integer := 16;
    data_width_g : integer := 32
  );
  port(
    clka : in std_logic;
    clkb : in std_logic;
    ena : in std_logic;
    enb : in std_logic;
    wea : in std_logic;
    web : in std_logic;
    strba : in std_logic_vector(data_width_g/8-1 downto 0);
    strbb : in std_logic_vector(data_width_g/8-1 downto 0);
    addra : in std_logic_vector(addr_width_g-1 downto 0);
    addrb : in std_logic_vector(addr_width_g-1 downto 0);
    dia : in std_logic_vector(data_width_g-1 downto 0);
    dib : in std_logic_vector(data_width_g-1 downto 0);
    doa : out std_logic_vector(data_width_g-1 downto 0);
    dob : out std_logic_vector(data_width_g-1 downto 0)
  );
end rams_be;

architecture sim of rams_be is
  type ram_type is array (2**addr_width_g-1 downto 0)
    of std_logic_vector(data_width_g-1 downto 0);
  shared variable RAM : ram_type;
begin
  
  process (CLKA)
  begin
    if rising_edge(CLKA) then
      if ENA = '1' then
        DOA <= RAM(conv_integer(ADDRA));
        if WEA = '1' then
          for i in strba'range loop
            if strba(i) = '1' then
              RAM(conv_integer(ADDRA))((i+1)*8-1 downto i*8)
                := DIA((i+1)*8-1 downto i*8);
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;
  
  process (CLKB)
  begin
    if rising_edge(CLKB) then
      if ENB = '1' then
        DOB <= RAM(conv_integer(ADDRB));
        if WEB = '1' then
          for i in strbb'range loop
            if strbb(i) = '1' then
              RAM(conv_integer(ADDRB))((i+1)*8-1 downto i*8)
                := DIB((i+1)*8-1 downto i*8);
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;
  
end sim;


  
    
