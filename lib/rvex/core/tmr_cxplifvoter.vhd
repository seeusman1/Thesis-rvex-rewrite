
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
use work.core_intIface_pkg.all;
use work.core_trap_pkg.all;
use work.core_pipeline_pkg.all;


--=============================================================================
entity tmr_cxplifvoter is
--=============================================================================
	
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type 
  );


  port	(
	  
	-- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic := '1';
	  
	--Active high fault tolerance enable  
	start_ft					: in std_logic;
	  
	--signal representing active pipelane groups for fault tolerance mode
	config_signal				: in std_logic_vector (3 downto 0); 
	  
	    
    ---------------------------------------------------------------------------
    -- Signals that go into CXPLIF Majority voter
    ---------------------------------------------------------------------------
  blockReconfig_arb      : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  irqAck_arb             : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  idle_arb               : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  PC_arb                 : in rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  limmValid_arb          : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  valid_arb              : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  brkValid_arb           : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  invalUntilBR_arb       : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  brLinkWritePort_arb    : in pl2cxreg_writePort_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  trapInfo_arb           : in trap_info_array   (2**CFG.numLaneGroupsLog2-1 downto 0);
  trapPoint_arb          : in rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  exDbgTrapInfo_arb      : in trap_info_array   (2**CFG.numLaneGroupsLog2-1 downto 0);
  stop_arb               : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  rfi_arb                : in std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
	  
  stall                  : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  cfg2cxplif_active      : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
	  
	  
	---------------------------------------------------------------------------
    -- Signals that come out of CXPLIF Majority voter
    ---------------------------------------------------------------------------


    cxplif2cfg_blockReconfig    : out std_logic;
    cxplif2rctrl_irqAck         : out std_logic;
    cxplif2rctrl_idle           : out std_logic;
    cxplif2cxreg_stall          : out std_logic;
    cxplif2cxreg_idle           : out std_logic;
    cxplif2cxreg_stop           : out std_logic;
    cxplif2cxreg_brWriteData    : out rvex_brRegData_type;  
    cxplif2cxreg_brWriteEnable  : out rvex_brRegData_type; 
    cxplif2cxreg_linkWriteData  : out std_logic_vector(31 downto 0);
    cxplif2cxreg_linkWriteEnable: out std_logic;
    cxplif2cxreg_nextPC         : out std_logic_vector(31 downto 0);
    cxplif2cxreg_overridePC_ack : out std_logic;
    cxplif2cxreg_trapInfo       : out trap_info_type; 
    cxplif2cxreg_trapPoint      : out std_logic_vector(31 downto 0);
    cxplif2cxreg_rfi            : out std_logic;
    cxplif2cxreg_exDbgTrapInfo  : out trap_info_type;  
    cxplif2cxreg_resuming_ack   : out std_logic
	  
	    
  );

end entity tmr_cxplifvoter;
	

--=============================================================================
architecture structural of tmr_cxplifvoter is
--=============================================================================
	
	
	--add signals here
	signal start									: std_logic := '0';
	signal start_array								: std_logic_vector (0 downto 0) := (others => '0');
	
	--zero initialization of trap info type
	constant zero_init								: trap_info_type := ( active => '0',
														  				cause => (others => '0'),
														  				arg => (others => '0')
																		);

	-- internal signals for address
    signal cxplif2cfg_blockReconfig_temp    		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2rctrl_irqAck_temp         		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2rctrl_idle_temp           		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_stall_temp          		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_idle_temp           		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_stop_temp           		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_brWriteData_temp    		: rvex_brRegData_array(2**CFG.numContextsLog2-1 downto 0); 
    signal cxplif2cxreg_brWriteEnable_temp  		: rvex_brRegData_array(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_linkWriteData_temp  		: rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_linkWriteEnable_temp		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_nextPC_temp         		: rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_overridePC_ack_temp 		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_trapInfo_temp       		: trap_info_array(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_trapPoint_temp      		: rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_rfi_temp            		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal cxplif2cxreg_exDbgTrapInfo_temp  		: trap_info_array(2**CFG.numContextsLog2-1 downto 0); 
    signal cxplif2cxreg_resuming_ack_temp   		: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

	
--=============================================================================
begin -- architecture
--=============================================================================
		

	---------------------------------------------------------------------------
	
--	  cxplif2cfg_blockReconfig(ctxt)      <= blockReconfig_arb(laneGroup) and cfg2cxplif_active(ctxt);
--    cxplif2rctrl_irqAck(ctxt)           <= irqAck_arb(laneGroup) and cfg2cxplif_active(ctxt);
--    cxplif2rctrl_idle(ctxt)             <= idle_arb(laneGroup) or not cfg2cxplif_active(ctxt);
--    cxplif2cxreg_stall(ctxt)            <= stall(laneGroup) or not cfg2cxplif_active(ctxt);
--    cxplif2cxreg_idle(ctxt)             <= idle_arb(laneGroup) or not cfg2cxplif_active(ctxt);
--    cxplif2cxreg_stop(ctxt)             <= stop_arb(laneGroup);
--    cxplif2cxreg_brWriteData(ctxt)      <= brLinkWritePort_arb(laneGroup).brData(S_SWB);
--    cxplif2cxreg_brWriteEnable(ctxt)    <= brLinkWritePort_arb(laneGroup).brWriteEnable(S_SWB);
--    cxplif2cxreg_linkWriteData(ctxt)    <= brLinkWritePort_arb(laneGroup).linkData(S_SWB);
--    cxplif2cxreg_linkWriteEnable(ctxt)  <= brLinkWritePort_arb(laneGroup).linkWriteEnable(S_SWB);
--    cxplif2cxreg_nextPC(ctxt)           <= PC_arb(laneGroup);
--    cxplif2cxreg_overridePC_ack(ctxt)   <= valid_arb(laneGroup);
--    cxplif2cxreg_trapInfo(ctxt)         <= trapInfo_arb(laneGroup);
--    cxplif2cxreg_trapPoint(ctxt)        <= trapPoint_arb(laneGroup);
--    cxplif2cxreg_rfi(ctxt)              <= rfi_arb(laneGroup);
--    cxplif2cxreg_exDbgTrapInfo(ctxt)    <= exDbgTrapInfo_arb(laneGroup);
--    cxplif2cxreg_resuming_ack(ctxt)     <= valid_arb(laneGroup);
	

	---------------------------------------------------------------------------
    -- Internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(blockReconfig_arb, cfg2cxplif_active, irqAck_arb, idle_arb, stall, stop_arb, 
								   brLinkWritePort_arb, PC_arb, valid_arb, trapInfo_arb, trapPoint_arb, rfi_arb, exDbgTrapInfo_arb)
		variable index	: integer	:= 0;
	begin

			cxplif2cfg_blockReconfig_temp  		<= (others => '0');
		    cxplif2rctrl_irqAck_temp           	<= (others => '0');
		    cxplif2rctrl_idle_temp            	<= (others => '0');
		    cxplif2cxreg_stall_temp            	<= (others => '0');
		    cxplif2cxreg_idle_temp             	<= (others => '0');
		    cxplif2cxreg_stop_temp             	<= (others => '0');
			cxplif2cxreg_brWriteData_temp		<= (others => (others => '0'));
			cxplif2cxreg_brWriteEnable_temp		<= (others => (others => '0'));
			cxplif2cxreg_linkWriteData_temp		<= (others => (others => '0'));
			cxplif2cxreg_linkWriteEnable_temp	<= (others => '0');
			cxplif2cxreg_nextPC_temp			<= (others => (others => '0'));
			cxplif2cxreg_overridePC_ack_temp	<= (others => '0');
			cxplif2cxreg_trapInfo_temp			<= (others => zero_init);
			cxplif2cxreg_trapPoint_temp			<= (others => (others => '0'));
			cxplif2cxreg_rfi_temp				<= (others => '0');
			cxplif2cxreg_exDbgTrapInfo_temp		<= (others => zero_init);
			cxplif2cxreg_resuming_ack_temp		<= (others => '0');
			
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
						cxplif2cfg_blockReconfig_temp(index)			<= blockReconfig_arb(i) and cfg2cxplif_active(0); -- ctxt shoudl be FT ctxt and laneGroup should be i
						cxplif2rctrl_irqAck_temp(index)           		<= irqAck_arb(i) and cfg2cxplif_active(0);
		    			cxplif2rctrl_idle_temp(index)             		<= idle_arb(i) or not cfg2cxplif_active(0);
		    			cxplif2cxreg_stall_temp(index)            		<= stall(i) or not cfg2cxplif_active(0);
		    			cxplif2cxreg_idle_temp(index)             		<= idle_arb(i) or not cfg2cxplif_active(0);
		    			cxplif2cxreg_stop_temp(index)             		<= stop_arb(i);
						cxplif2cxreg_brWriteData_temp(index)			<= brLinkWritePort_arb(i).brData(S_SWB);
    					cxplif2cxreg_brWriteEnable_temp(index)    		<= brLinkWritePort_arb(i).brWriteEnable(S_SWB);
    					cxplif2cxreg_linkWriteData_temp(index)  		<= brLinkWritePort_arb(i).linkData(S_SWB);
						cxplif2cxreg_linkWriteEnable_temp(index)		<= brLinkWritePort_arb(i).linkWriteEnable(S_SWB);
						cxplif2cxreg_nextPC_temp(index)		        	<= PC_arb(i);
    					cxplif2cxreg_overridePC_ack_temp(index)			<= valid_arb(i);
    					cxplif2cxreg_trapInfo_temp(index)				<= trapInfo_arb(i); 
    					cxplif2cxreg_trapPoint_temp(index)    		    <= trapPoint_arb(i);
						cxplif2cxreg_rfi_temp(index)              		<= rfi_arb(i);
    					cxplif2cxreg_exDbgTrapInfo_temp(index)			<= exDbgTrapInfo_arb(i); 
						cxplif2cxreg_resuming_ack_temp(index)     		<= valid_arb(i);
	
					
						index := index + 1;
				end if;
			end loop;
			index	:= 0;
	end process;
	

	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cfg_blockReconfig
    ---------------------------------------------------------------------------				
		
		cxplif2cfg_blockReconfig_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cfg_blockReconfig_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2cfg_blockReconfig_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2cfg_blockReconfig_temp(2),
				--input_3		=> '0',
				output		=> cxplif2cfg_blockReconfig
			);

	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2rctrl_irqAck
    ---------------------------------------------------------------------------				
		
		cxplif2rctrl_irqAck_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2rctrl_irqAck_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2rctrl_irqAck_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2rctrl_irqAck_temp(2),
				--input_3		=> '0',
				output		=> cxplif2rctrl_irqAck
			);

	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2rctrl_idle
    ---------------------------------------------------------------------------				
		
		cxplif2rctrl_idle_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2rctrl_idle_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2rctrl_idle_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2rctrl_idle_temp(2),
				--input_3		=> '0',
				output		=> cxplif2rctrl_idle
			);

	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_stall
    ---------------------------------------------------------------------------				
		
		cxplif2cxreg_stall_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_stall_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_stall_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_stall_temp(2),
				--input_3		=> '0',
				output		=> cxplif2cxreg_stall
			);

	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_idle
    ---------------------------------------------------------------------------				
		
		cxplif2cxreg_idle_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_idle_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_idle_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_idle_temp(2),
				--input_3		=> '0',
				output		=> cxplif2cxreg_idle
			);

	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_stop
    ---------------------------------------------------------------------------				
		
		cxplif2cxreg_stop_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_stop_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_stop_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_stop_temp(2),
				--input_3		=> '0',
				output		=> cxplif2cxreg_stop
			);



	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_brWriteData
    ---------------------------------------------------------------------------				
		
	cxplif2cxreg_brWriteData_voter: for i in 0 to 7 generate
		cxplif2cxreg_brWriteData_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_brWriteData_temp(0)(i),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_brWriteData_temp(1)(i),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_brWriteData_temp(2)(i),
				--input_3		=> '0',
				output		=> cxplif2cxreg_brWriteData(i)
			);
	end generate;
	
		
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_brWriteEnable
    ---------------------------------------------------------------------------				
		
	cxplif2cxreg_brWriteEnable_voter: for i in 0 to 7 generate
		cxplif2cxreg_brWriteEnable_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_brWriteEnable_temp(0)(i),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_brWriteEnable_temp(1)(i),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_brWriteEnable_temp(2)(i),
				--input_3		=> '0',
				output		=> cxplif2cxreg_brWriteEnable(i)
			);
	end generate;
	
				
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_linkWriteData
    ---------------------------------------------------------------------------				
		
	cxplif2cxreg_linkWriteData_voter: for i in 0 to 31 generate
		cxplif2cxreg_linkWriteData_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_linkWriteData_temp(0)(i),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_linkWriteData_temp(1)(i),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_linkWriteData_temp(2)(i),
				--input_3		=> '0',
				output		=> cxplif2cxreg_linkWriteData(i)
			);
	end generate;
			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_linkWriteEnable
    ---------------------------------------------------------------------------				
		
		cxplif2cxreg_linkWriteEnable_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_linkWriteEnable_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_linkWriteEnable_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_linkWriteEnable_temp(2),
				--input_3		=> '0',
				output		=> cxplif2cxreg_linkWriteEnable
			);

			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_nextPC
    ---------------------------------------------------------------------------				
		
	cxplif2cxreg_nextPC_voter: for i in 0 to 31 generate
		cxplif2cxreg_nextPC_bank: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_nextPC_temp(0)(i),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_nextPC_temp(1)(i),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_nextPC_temp(2)(i),
				--input_3		=> '0',
				output		=> cxplif2cxreg_nextPC(i)
			);
	end generate;

	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_overridePC_ack
    ---------------------------------------------------------------------------				
		
		cxplif2cxreg_overridePC_ack_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_overridePC_ack_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_overridePC_ack_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_overridePC_ack_temp(2),
				--input_3		=> '0',
				output		=> cxplif2cxreg_overridePC_ack
			);
			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_trapInfo									
    ---------------------------------------------------------------------------				
		
	-- PC Majority voter bank for cxplif2cxreg_trapInfo.active			
	cxplif2cxreg_trapInfo_active_voter: entity work.tmr_voter
				port map (
					input_1		=> cxplif2cxreg_trapInfo_temp(0).active,
					--input_1		=> '0',
					input_2		=> cxplif2cxreg_trapInfo_temp(1).active,
					--input_2		=> '0',
					input_3		=> cxplif2cxreg_trapInfo_temp(2).active,
					--input_3		=> '0',
					output		=> cxplif2cxreg_trapInfo.active
				);
	

    -- PC Majority voter bank for cxplif2cxreg_trapInfo.cause		
	cxplif2cxreg_trapInfo_cause_voter: for i in 0 to RVEX_TRAP_CAUSE_SIZE-1 generate
			cxplif2cxreg_trapInfo_cause_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> cxplif2cxreg_trapInfo_temp(0).cause(i),
					--input_1		=> '0',
					input_2		=> cxplif2cxreg_trapInfo_temp(1).cause(i),
					--input_2		=> '0',
					input_3		=> cxplif2cxreg_trapInfo_temp(2).cause(i),
					--input_3		=> '0',
					output		=> cxplif2cxreg_trapInfo.cause(i)
				);
	end generate;
	
			

    -- PC Majority voter bank for cxplif2cxreg_trapInfo.arg		
	cxplif2cxreg_trapInfo_arg_voter: for i in 0 to 31 generate
			cxplif2cxreg_trapInfo_arg_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> cxplif2cxreg_trapInfo_temp(0).arg(i),
					--input_1		=> '0',
					input_2		=> cxplif2cxreg_trapInfo_temp(1).arg(i),
					--input_2		=> '0',
					input_3		=> cxplif2cxreg_trapInfo_temp(2).arg(i),
					--input_3		=> '0',
					output		=> cxplif2cxreg_trapInfo.arg(i)
				);
	end generate;
		


	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_trapPoint									
    ---------------------------------------------------------------------------				
		
	cxplif2cxreg_trapPoint_voter: for i in 0 to 31 generate
		cxplif2cxreg_trapPoint_bank: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_trapPoint_temp(0)(i),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_trapPoint_temp(1)(i),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_trapPoint_temp(2)(i),
				--input_3		=> '0',
				output		=> cxplif2cxreg_trapPoint(i)
			);
	end generate;
			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_rfi
    ---------------------------------------------------------------------------				
		
		cxplif2cxreg_rfi_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_rfi_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_rfi_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_rfi_temp(2),
				--input_3		=> '0',
				output		=> cxplif2cxreg_rfi
			);
			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for 	cxplif2cxreg_exDbgTrapInfo							
    ---------------------------------------------------------------------------				
		
	-- PC Majority voter bank for cxplif2cxreg_exDbgTrapInfo.active			
	cxplif2cxreg_exDbgTrapInfo_active_voter: entity work.tmr_voter
				port map (
					input_1		=> cxplif2cxreg_exDbgTrapInfo_temp(0).active,
					--input_1		=> '0',
					input_2		=> cxplif2cxreg_exDbgTrapInfo_temp(1).active,
					--input_2		=> '0',
					input_3		=> cxplif2cxreg_exDbgTrapInfo_temp(2).active,
					--input_3		=> '0',
					output		=> cxplif2cxreg_exDbgTrapInfo.active
				);
	

    -- PC Majority voter bank for cxplif2cxreg_exDbgTrapInfo.cause		
	cxplif2cxreg_exDbgTrapInfo_cause_voter: for i in 0 to RVEX_TRAP_CAUSE_SIZE-1 generate
			cxplif2cxreg_exDbgTrapInfo_cause_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> cxplif2cxreg_exDbgTrapInfo_temp(0).cause(i),
					--input_1		=> '0',
					input_2		=> cxplif2cxreg_exDbgTrapInfo_temp(1).cause(i),
					--input_2		=> '0',
					input_3		=> cxplif2cxreg_exDbgTrapInfo_temp(2).cause(i),
					--input_3		=> '0',
					output		=> cxplif2cxreg_exDbgTrapInfo.cause(i)
				);
	end generate;
	
			

    -- PC Majority voter bank for cxplif2cxreg_exDbgTrapInfo.arg		
	cxplif2cxreg_exDbgTrapInfo_arg_voter: for i in 0 to 31 generate
			cxplif2cxreg_exDbgTrapInfo_arg_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> cxplif2cxreg_exDbgTrapInfo_temp(0).arg(i),
					--input_1		=> '0',
					input_2		=> cxplif2cxreg_exDbgTrapInfo_temp(1).arg(i),
					--input_2		=> '0',
					input_3		=> cxplif2cxreg_exDbgTrapInfo_temp(2).arg(i),
					--input_3		=> '0',
					output		=> cxplif2cxreg_exDbgTrapInfo.arg(i)
				);
	end generate;
		


			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cxplif2cxreg_resuming_ack
    ---------------------------------------------------------------------------				
		
		cxplif2cxreg_resuming_ack_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2cxreg_resuming_ack_temp(0),
				--input_1		=> '0',
				input_2		=> cxplif2cxreg_resuming_ack_temp(1),
				--input_2		=> '0',
				input_3		=> cxplif2cxreg_resuming_ack_temp(2),
				--input_3		=> '0',
				output		=> cxplif2cxreg_resuming_ack
			);
			
					
			
--	  cxplif2cfg_blockReconfig      <= blockReconfig_arb(laneGroup) and cfg2cxplif_active(ctxt);
--    cxplif2rctrl_irqAck           <= irqAck_arb(laneGroup) and cfg2cxplif_active(ctxt);
--    cxplif2rctrl_idle             <= idle_arb(laneGroup) or not cfg2cxplif_active(ctxt);
--    cxplif2cxreg_stall            <= stall(laneGroup) or not cfg2cxplif_active(ctxt);
--    cxplif2cxreg_idle             <= idle_arb(laneGroup) or not cfg2cxplif_active(ctxt);
--    cxplif2cxreg_stop             <= stop_arb(laneGroup);
--    cxplif2cxreg_brWriteData      <= brLinkWritePort_arb(laneGroup).brData(S_SWB);
--    cxplif2cxreg_brWriteEnable    <= brLinkWritePort_arb(laneGroup).brWriteEnable(S_SWB);
--    cxplif2cxreg_linkWriteData    <= brLinkWritePort_arb(laneGroup).linkData(S_SWB);
--    cxplif2cxreg_linkWriteEnable  <= brLinkWritePort_arb(laneGroup).linkWriteEnable(S_SWB);
--    cxplif2cxreg_nextPC           <= PC_arb(laneGroup);
--    cxplif2cxreg_overridePC_ack   <= valid_arb(laneGroup);
--    cxplif2cxreg_trapInfo         <= trapInfo_arb(laneGroup);
--    cxplif2cxreg_trapPoint        <= trapPoint_arb(laneGroup);
--    cxplif2cxreg_rfi              <= rfi_arb(laneGroup);
--    cxplif2cxreg_exDbgTrapInfo    <= exDbgTrapInfo_arb(laneGroup);
--    cxplif2cxreg_resuming_ack     <= valid_arb(laneGroup);

end structural;
			

	