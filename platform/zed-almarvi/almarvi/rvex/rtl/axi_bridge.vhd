-- r-VEX processor
-- Copyright (C) 2008-2016 by TU Delft.
-- All Rights Reserved.

-- THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
-- YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.

-- No portion of this work may be used by any commercial entity, or for any
-- commercial purpose, without the prior, written permission of TU Delft.
-- Nonprofit and noncommercial use is permitted as described below.

-- 1. r-VEX is provided AS IS, with no warranty of any kind, express
-- or implied. The user of the code accepts full responsibility for the
-- application of the code and the use of any results.

-- 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
-- downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
-- educational, noncommercial research, and noncommercial scholarship
-- purposes provided that this notice in its entirety accompanies all copies.
-- Copies of the modified software can be delivered to persons who use it
-- solely for nonprofit, educational, noncommercial research, and
-- noncommercial scholarship purposes provided that this notice in its
-- entirety accompanies all copies.

-- 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
-- PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).

-- 4. No nonprofit user may place any restrictions on the use of this software,
-- including as modified by the user, by any other authorized user.

-- 5. Noncommercial and nonprofit users may distribute copies of r-VEX
-- in compiled or binary form as set forth in Section 2, provided that
-- either: (A) it is accompanied by the corresponding machine-readable source
-- code, or (B) it is accompanied by a written offer, with no time limit, to
-- give anyone a machine-readable copy of the corresponding source code in
-- return for reimbursement of the cost of distribution. This written offer
-- must permit verbatim duplication by anyone, or (C) it is distributed by
-- someone who received only the executable form, and is accompanied by a
-- copy of the written offer of source code.

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.bus_pkg.all;

--=============================================================================
-- This unit bridges an AXI slave interface to an rvex bus master.
-------------------------------------------------------------------------------
entity axi_bridge is
--=============================================================================
  generic (
    
    -- Width of the AXI address ports. Must be at least 13+NUM_CONTEXTS_LOG2 to
    -- accomodate the r-VEX control register file, at least 2+IMEM_DEPTH_LOG2
    -- for the instruction memory and at least 2+DMEM_DEPTH_LOG2 for the data
    -- memory.
    AXI_ADDRW_G                 : integer := 17
    
  );
  port (
  
    -- System control.
    areset                      : in  std_logic;
    reset                       : in  std_logic;
    clk                         : in  std_logic;
    
    -- AXI read address channel.
    s_axi_araddr                : in  std_logic_vector(axi_addrw_g-1 downto 0);
    s_axi_arvalid               : in  std_logic;
    s_axi_arready               : out std_logic;
    
    -- AXI read data channel.
    s_axi_rdata                 : out std_logic_vector(31 downto 0);
    s_axi_rresp                 : out std_logic_vector(1 downto 0);
    s_axi_rvalid                : out std_logic;
    s_axi_rready                : in  std_logic;
    
    -- AXI write address channel.
    s_axi_awaddr                : in  std_logic_vector(axi_addrw_g-1 downto 0);
    s_axi_awvalid               : in  std_logic;
    s_axi_awready               : out std_logic;
    
    -- AXI write data channel.
    s_axi_wdata                 : in  std_logic_vector(31 downto 0);
    s_axi_wstrb                 : in  std_logic_vector(3 downto 0);
    s_axi_wvalid                : in  std_logic;
    s_axi_wready                : out std_logic;
    
    -- AXI write response channel.
    s_axi_bresp                 : out std_logic_vector(1 downto 0);
    s_axi_bvalid                : out std_logic;
    s_axi_bready                : in  std_logic;
    
    -- r-VEX bus master.
    bridge2bus                  : out bus_mst2slv_type;
    bus2bridge                  : in  bus_slv2mst_type
    
  );
end axi_bridge;

--=============================================================================
architecture Behavioral of axi_bridge is
--=============================================================================
  
  -- AXI bridge FSM state.
  type state_type is (
    IDLE, READ_1, READ_2, WRITE_0, WRITE_1, WRITE_2
  );
  signal state                  : state_type;
  
  -- Bus request registers using AXI endianness.
  signal address                : rvex_address_type;
  signal readEnable             : std_logic;
  signal writeEnable            : std_logic;
  signal writeMask              : rvex_mask_type;
  signal writeData              : rvex_data_type;
  
  -- Bus read reply using AXI endianness.
  signal readData               : rvex_data_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Handle the AXI protocol.
  axi_proc: process (areset, clk) is
  begin
    if areset = '1' then
      
      -- Asynchronously reset FSM state.
      state <= IDLE;
      
      -- Asynchronously reset AXI output registers.
      s_axi_arready <= '0';
      s_axi_rdata   <= (others => '0');
      s_axi_rresp   <= "00";
      s_axi_rvalid  <= '0';
      s_axi_awready <= '0';
      s_axi_wready  <= '0';
      s_axi_bresp   <= "00";
      s_axi_bvalid  <= '0';
      
    elsif rising_edge(clk) then
      
      -- Not ready for anything until told otherwise.
      s_axi_arready <= '0';
      s_axi_awready <= '0';
      s_axi_wready  <= '0';
      
      if reset = '1' then
        
        -- Synchronously reset FSM state.
        state <= IDLE;
        
        -- Synchronously reset AXI response registers.
        s_axi_rdata   <= (others => '0');
        s_axi_rresp   <= "00";
        s_axi_rvalid  <= '0';
        s_axi_bresp   <= "00";
        s_axi_bvalid  <= '0';
        
        -- Synchronously reset r-VEX bus request registers.
        address       <= (others => '0');
        readEnable    <= '0';
        writeEnable   <= '0';
        writeMask     <= "0000";
        writeData     <= (others => '0');
        
      else
        
        -- Handle the FSM.
        case state is
          
          ---------------------------------------------------------------------
          -- Idle: no transfers have been accepted.
          ---------------------------------------------------------------------
          when IDLE =>
            
            -- Invalidate read/write responses.
            s_axi_rvalid <= '0';
            s_axi_bvalid <= '0';
            
            -- Accept new transfers.
            if s_axi_awvalid = '1' then
              
              -- Accept write request and store the address.
              s_axi_awready <= '1';
              address(AXI_ADDRW_G-1 downto 0) <= s_axi_awaddr;
              
              -- We're also ready to accept the write data, but we might not
              -- get it immediately.
              s_axi_wready <= '1';
              if s_axi_wvalid = '1' then
                
                -- Start the r-VEX bus transfer and wait for the result.
                writeEnable <= '1';
                writeMask <= s_axi_wstrb;
                writeData <= s_axi_wdata;
                state <= WRITE_1;
                
              else
                
                -- Wait for the rest of the request.
                state <= WRITE_0;
                
              end if;
              
            elsif (s_axi_arvalid = '1') then
              
              -- Accept read request and store the address.
              s_axi_arready <= '1';
              address(AXI_ADDRW_G-1 downto 0) <= s_axi_araddr;
              
              -- Start the r-VEX bus transfer and wait for the result.
              readEnable <= '1';
              state <= READ_1;
              
            end if;
          
          ---------------------------------------------------------------------
          -- Read transfers.
          ---------------------------------------------------------------------
          when READ_1 =>
            
            -- Wait for the r-VEX bus to have a result.
            if bus2bridge.ack = '1' then
              
              -- Stop requesting.
              readEnable <= '0';
              
              -- Forward the data to the AXI read result channel.
              s_axi_rdata  <= readData;
              s_axi_rresp  <= (1 => bus2bridge.fault, 0 => '0');
              s_axi_rvalid <= '1';
              
              -- Wait for the AXI master to accept the data.
              if s_axi_rready = '1' then
                state <= IDLE;
              else
                state <= READ_2;
              end if;
              
            end if;
            
          when READ_2 =>
            
            -- Wait for the AXI master to accept the read data.
            if s_axi_rready = '1' then
              state <= IDLE;
            end if;
            
          ---------------------------------------------------------------------
          -- Write transfers.
          ---------------------------------------------------------------------
          when WRITE_0 =>
            
            -- Wait for the write data.
            if s_axi_wvalid = '1' then
              
              -- Start the r-VEX bus transfer and wait for the result.
              writeEnable <= '1';
              writeMask <= s_axi_wstrb;
              writeData <= s_axi_wdata;
              state <= WRITE_1;
            
            else
              
              -- We're still ready.
              s_axi_wready <= '1';
              
            end if;
          
          when WRITE_1 =>
          
            -- Wait for the r-VEX bus to have a result.
            if bus2bridge.ack = '1' then
              
              -- Stop requesting.
              writeEnable <= '0';
              
              -- Forward the data to the AXI write result channel.
              s_axi_bresp  <= (1 => bus2bridge.fault, 0 => '0');
              s_axi_bvalid <= '1';
              
              -- Wait for the AXI master to accept the write result.
              if s_axi_bready = '1' then
                state <= IDLE;
              else
                state <= WRITE_2;
              end if;
              
            end if;
            
          when WRITE_2 =>
            
            -- Wait for the AXI master to accept the write result.
            if s_axi_bready = '1' then
              state <= IDLE;
            end if;
            
        end case;
        
      end if;
    end if;
  end process;
  
  -- Handle combinatorial r-VEX bus timing and pack the master-to-slave record.
  rvex_proc: process (
    address, readEnable, writeEnable, writeMask, writeData,
    bus2bridge.ack, bus2bridge.readData
  ) is
  begin
    bridge2bus              <= BUS_MST2SLV_IDLE;
    bridge2bus.address      <= address;
    bridge2bus.readEnable   <= readEnable  and not bus2bridge.ack;
    bridge2bus.writeEnable  <= writeEnable and not bus2bridge.ack;
    
    -- Endian-swap the write mask.
    bridge2bus.writeMask(0) <= writeMask(3);
    bridge2bus.writeMask(1) <= writeMask(2);
    bridge2bus.writeMask(2) <= writeMask(1);
    bridge2bus.writeMask(3) <= writeMask(0);
    
    -- Endian-swap the write data.
    bridge2bus.writeData( 7 downto  0) <= writeData(31 downto 24);
    bridge2bus.writeData(15 downto  8) <= writeData(23 downto 16);
    bridge2bus.writeData(23 downto 16) <= writeData(15 downto  8);
    bridge2bus.writeData(31 downto 24) <= writeData( 7 downto  0);
    
    -- Endian-swap the read data.
    readData( 7 downto  0) <= bus2bridge.readData(31 downto 24);
    readData(15 downto  8) <= bus2bridge.readData(23 downto 16);
    readData(23 downto 16) <= bus2bridge.readData(15 downto  8);
    readData(31 downto 24) <= bus2bridge.readData( 7 downto  0);
    
  end process;
  
end Behavioral;

