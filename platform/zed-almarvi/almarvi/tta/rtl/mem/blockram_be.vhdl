
--  Xilinx Single Port Byte-Write Read First RAM
--  This code implements a parameterizable single-port byte-write read-first memory where when data
--  is written to the memory, the output reflects the prior contents of the memory location.
--  If the output data is not needed during writes or the last read value is desired to be
--  retained, it is suggested to use Single Port.Byte-write Enable.No Change Mode template as it is more power efficient.
--  If a reset or enable is not necessary, it may be tied off or removed from the code.
--  Modify the parameters for the desired RAM characteristics.

-- Following libraries have to be used
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;

entity blockram_be is  generic (
    addrw : integer := 15;
    dataw : integer := 32);
  port (
    clk   : in std_logic;
    we    : in std_logic;
    en    : in std_logic;
    addr  : in std_logic_vector(addrw-1 downto 0);
    di    : in std_logic_vector(dataw-1 downto 0);
    do    : out std_logic_vector(dataw-1 downto 0);
    bena  : in std_logic_vector(dataw/8-1 downto 0)
    );                     
end blockram_be;

architecture rtl of blockram_be is  

--Insert the following in the architecture before the begin keyword 
--  The following function calculates the address width based on specified RAM depth
function clogb2( depth : natural) return integer is
variable temp    : integer := depth;
variable ret_val : integer := 0; 
begin					
  while temp > 1 loop
    ret_val := ret_val + 1;
    temp    := temp / 2;     
  end loop;

  return ret_val;
end function;


-- Note : 
-- If the chosen width and depth values are low, Synthesis will infer Distributed RAM. 
-- C_RAM_DEPTH should be a power of 2
constant C_NB_COL     : integer := dataw/8;                                                 -- Specify number of columns 
constant C_COL_WIDTH  : integer := 8;                                                       -- Specify column width (byte width)
constant C_RAM_DEPTH : integer := 2**addrw;                                                 -- Specify RAM depth (number of entries)
constant C_RAM_PERFORMANCE : string := "LOW_LATENCY"; 
--constant C_INIT_FILE : string := <init_file>;                                         -- Specify name/location of RAM initialization file if using one (leave blank if not)
signal addra : std_logic_vector(clogb2(C_RAM_DEPTH)-1 downto 0);                          -- Address bus, width determined from RAM_DEPTH
signal dina  : std_logic_vector(C_NB_COL*C_COL_WIDTH-1 downto 0);                         -- RAM input data
--signal clka  : std_logic;                                                                 -- Clock
signal wea   : std_logic_vector(C_NB_COL-1 downto 0);                                     -- Byte-Write enable
signal ena   : std_logic;                                                                 -- RAM Enable, for additional power savings, disable port when not in use
signal douta : std_logic_vector(C_NB_COL*C_COL_WIDTH-1 downto 0);                                  -- RAM output data
--signal douta_reg : std_logic_vector(C_NB_COL*C_COL_WIDTH-1 downto 0) := (others => '0');           -- RAM output data when RAM_PERFORMANCE = HIGH_PERFORMANCE

-- not used for low latency ram
--signal rsta  : std_logic;                                                                 -- Output reset (does not affect memory contents)
--signal regcea: std_logic;                                                                 -- Output register enable

type ram_type is array (C_RAM_DEPTH-1 downto 0) of std_logic_vector (C_NB_COL*C_COL_WIDTH-1 downto 0);      -- 2D Array Declaration for RAM signal
signal ram_data : std_logic_vector(C_NB_COL*C_COL_WIDTH-1 downto 0) ;                                   


-- Define RAM
signal RAM_ARR : ram_type;

begin

  ena <= en;
  wea <= bena when we = '1' else (others => '0');
  do <= douta;
  dina <= di;
  addra <= addr;
  

--Insert the following in the architecture after the begin keyword
process(clk)
begin
    if(clk'event and clk = '1') then
        if(ena = '1') then
            for i in 0 to C_NB_COL-1 loop 
                if(wea(i) = '1') then
                    RAM_ARR(to_integer(unsigned(addra)))((i+1)*C_COL_WIDTH-1 downto i*C_COL_WIDTH) <= dina((i+1)*C_COL_WIDTH-1 downto i*C_COL_WIDTH);
                end if;
            end loop;
            ram_data <= RAM_ARR(to_integer(unsigned(addra)));
        end if;
    end if;
end process;

--  Following code generates LOW_LATENCY (no output register)
--  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing

no_output_register : if C_RAM_PERFORMANCE = "LOW_LATENCY" generate
  douta <= ram_data;
end generate;

--  Following code generates HIGH_PERFORMANCE (use output register) 
--  Following is a 2 clock cycle read latency with improved clock-to-out timing

--output_register : if C_RAM_PERFORMANCE = "HIGH_PERFORMANCE"  generate
--process(<clk>)
--    begin
--        if(<clk>'event and <clk> = '1') then
--            if(<rsta> = '1') then
--                <douta_reg> <= (others => '0');
--            elsif(<regcea> = '1') then
--                <douta_reg> <= <ram_data>;
--            end if;
--        end if;
--end process;
--<douta> <= <douta_reg>;
--end generate;

							
end rtl;
