
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
--use work.core_intIface_pkg.all;
--use work.core_trap_pkg.all;
--use work.core_pipeline_pkg.all;
--use work.core_ctrlRegs_pkg.all;


--=============================================================================
entity tmr_dmemvoter is
--=============================================================================
	
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type 
  );


  port	(
    ---------------------------------------------------------------------------
    -- Signals that go into DMEM Majority voter
    ---------------------------------------------------------------------------
    -- Data memory addresses from each pipelane group. Note that a section
    -- of the address space 1kiB in size must be mapped to the core control
    -- registers, making that section of the data memory inaccessible.
    -- The start address of this section is configurable with CFG.
    rv2dmemvoter_addr                : in rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high read enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must fetch the data at the address
    -- specified by the associated vector in dmem_addr.
    rv2dmemvoter_readEnable          : in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write data from the rvex to the DMEM majority voter.
    rv2dmemvoter_writeData           : in rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write byte mask from the rvex to the DMEM majority voter, active high.
    rv2dmemvoter_writeMask           : in rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active write enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must write the data in
    -- dmem_writeData to the address specified by dmem_addr, respecting the
    -- byte mask specified by dmem_writeMask.
    rv2dmemvoter_writeEnable         : in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- (L_MEM clock cycles delay with clkEn high and stallOut low; L_MEM is set
    -- in core_pipeline_pkg.vhd)
    
    -- Data output from data memory to rvex.
    dmem2dmemvoter_readData            : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	  
	  
	  
	  
	  
	  
	---------------------------------------------------------------------------
    -- Signals that come out of DMEM Majority voter
    ---------------------------------------------------------------------------
    -- Data memory addresses from each pipelane group. Note that a section
    -- of the address space 1kiB in size must be mapped to the core control
    -- registers, making that section of the data memory inaccessible.
    -- The start address of this section is configurable with CFG.
    dmemvoter2dmem_addr                : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high read enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must fetch the data at the address
    -- specified by the associated vector in dmem_addr.
    dmemvoter2dmem_readEnable          : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write data from the DMEM majority voter to the data memory.
    dmemvoter2dmem_writeData           : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write byte mask from the DMEM majority voter to the data memory, active high.
    dmemvoter2dmem_writeMask           : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active write enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must write the data in
    -- dmem_writeData to the address specified by dmem_addr, respecting the
    -- byte mask specified by dmem_writeMask.
    dmemvoter2dmem_writeEnable         : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- (L_MEM clock cycles delay with clkEn high and stallOut low; L_MEM is set
    -- in core_pipeline_pkg.vhd)
    
    -- Data output from data memory to rvex.
    dmemvoter2rv_readData            : out  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    

	  
  );

end entity tmr_dmemvoter;
	

--=============================================================================
architecture structural of tmr_dmemvoter is
--=============================================================================
	
	
	--add signals here
	signal start					: std_logic := '0';
	
	signal br2pcvoter_PC_s			: rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
	signal br2pcvoter_PC_s_temp		: rvex_address_array(2**CFG.numLanesLog2-1 downto 0);

	signal br2pcvoter_PC_s_result1	: std_logic_vector (31 downto 0) := (others => '0');
	signal br2pcvoter_PC_s_result2	: std_logic_vector (31 downto 0) := (others => '0');
	
	
	
--=============================================================================
begin -- architecture
--=============================================================================
		
	---------------------------------------------------------------------------
    -- stable start at rising edge of clock signal
    ---------------------------------------------------------------------------	
	
	stable_start: process(clk)
	begin
		if rising_edge(clk) then
			if (reset = '1') then
				start <= '0';
			else
				start <= start_ft;
			end if;
		end if;
	end process;
				
				
	---------------------------------------------------------------------------
    -- internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start, config_signal, br2pcvoter_PC)
		variable index	: integer	:= 0;
	begin
				
		if start = '0' then
			br2pcvoter_PC_s <= br2pcvoter_PC;
			br2pcvoter_PC_s_temp <= (others => (others => '0'));
			index := 0;
		else
			br2pcvoter_PC_s <= (others => (others => '0'));
			br2pcvoter_PC_s_temp <= (others => (others => '0'));
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					br2pcvoter_PC_s_temp(2*index)	<= br2pcvoter_PC(2*i); 
					br2pcvoter_PC_s_temp(2*index+1)	<= br2pcvoter_PC(2*i+1);
					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank between br and cxplif 
    ---------------------------------------------------------------------------				
		
	PCvoter1: for i in 0 to 31 generate
		ft_voter_bank1: entity work.tmr_voter
			port map (
				input_1		=> br2pcvoter_PC_s_temp(0)(i),
				--input_1		=> '0',
				input_2		=> br2pcvoter_PC_s_temp(2)(i),
				--input_2		=> '0',
				input_3		=> br2pcvoter_PC_s_temp(4)(i),
				--input_3		=> '0',
				output		=> br2pcvoter_PC_s_result1(i)
			);
	end generate;
	
			
	PCvoter2: for i in 0 to 31 generate
		ft_voter_bank2: entity work.tmr_voter
			port map (
				input_1		=> br2pcvoter_PC_s_temp(1)(i),
				--input_1		=> '0',
				input_2		=> br2pcvoter_PC_s_temp(3)(i),
				--input_2		=> '0',
				input_3		=> br2pcvoter_PC_s_temp(5)(i),
				--input_3		=> '0',
				output		=> br2pcvoter_PC_s_result2(i)
			);
	end generate;		
			
	
		
	---------------------------------------------------------------------------
    -- Recreate PC value after voter bank
    ---------------------------------------------------------------------------			
		
		
	nextpc_result: process (start, config_signal, br2pcvoter_PC_s, br2pcvoter_PC_s_result1, br2pcvoter_PC_s_result2)	
	begin
		if start = '0' then
			pcvoter2cxplif_PC	<=	br2pcvoter_PC_s;
		else
			pcvoter2cxplif_PC	<=	(others => (others => '0'));
		
			for i in 0 to 3 loop
				pcvoter2cxplif_PC(2*i)		<=	br2pcvoter_PC_s_result1;
				pcvoter2cxplif_PC(2*i+1)	<=	br2pcvoter_PC_s_result2;
			end loop;
		end if;
	end process;
			
end structural;