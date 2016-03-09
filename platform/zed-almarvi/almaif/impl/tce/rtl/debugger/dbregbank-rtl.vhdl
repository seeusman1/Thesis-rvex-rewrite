-------------------------------------------------------------------------------
-- Title      : Debugger register bank
-- Project    : tta debugger
-------------------------------------------------------------------------------
-- File       : dbregbank-rtl.vhdl
-- Author     : Tommi Zetterman  <tommi.zetterman@nokia.com>
-- Company    : Nokia Research Center
-- Created    : 2013-03-18
-- Last update: 2015-08-05
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: x
-------------------------------------------------------------------------------
-- Copyright (c) 2013 Nokia Research Center
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-03-18  1.0      zetterma	Created
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Status register
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.register_pkg.all;
use work.debugger_if.all;

entity status_register is
  generic (
    reg_width_g    : integer := 32;
    output_width_g : integer := 32
  );
  port(
    clk    : in std_logic;
    nreset : in std_logic;
    din    : in std_logic_vector(reg_width_g-1 downto 0);
    dout   : out std_logic_vector(output_width_g-1 downto 0)
    );
end status_register;

architecture rtl of status_register is
begin
  reg : process(clk, nreset)
  begin
    if (nreset = '0') then
      dout(reg_width_g-1 downto 0) <= (others => '0');
    elsif rising_edge(clk) then
      dout(reg_width_g-1 downto 0) <= din;
    end if;
  end process;
  dout(output_width_g-1 downto reg_width_g) <= (others => '0');
end rtl;

-------------------------------------------------------------------------------
-- Control register
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.register_pkg.all;

entity control_register is
  generic (
    reg_width_g    : integer := 32;
    output_width_g : integer := 32;
    reset_val_g    : integer 
  );
  port(
    clk    : in std_logic;
    nreset : in std_logic;
    we     : in std_logic;
    din    : in std_logic_vector(reg_width_g-1 downto 0);
    dout   : out std_logic_vector(output_width_g-1 downto 0)
  );
end control_register;

architecture rtl of control_register is
begin
  reg : process(clk, nreset)
  begin
    if (nreset = '0') then
      dout(reg_width_g-1 downto 0) <=
        std_logic_vector(to_unsigned(reset_val_g, reg_width_g));
    elsif rising_edge(clk) then
      if (we = '1') then
        dout(reg_width_g-1 downto 0) <= din;
      end if;
    end if;
  end process;
  dout(output_width_g-1 downto reg_width_g) <= (others => '0');
end rtl;

-------------------------------------------------------------------------------
-- RTL of Register bank
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.register_pkg.all;
use work.debugger_if.all;

architecture rtl of dbregbank is

  type dbstatus_t is array (0 to nof_status_registers_c-1)
    of std_logic_vector(data_width_g-1 downto 0);
  type dbcontrol_t is array (control_registers_c'range)
    of std_logic_vector(data_width_g-1 downto 0);
  signal dbstatus : dbstatus_t;
  signal dbcontrol : dbcontrol_t;

  signal ctrl_we : std_logic_vector(control_registers_c'range);

  -- gather input for TTA_STATUS register
  signal din_tta_status : std_logic_vector(status_registers_c(TTA_STATUS).bits-1
                                           downto 0);

  subtype bustrace_t is std_logic_vector(data_width_g-1 downto 0);
  type bustraces_arr_t is array (0 to nof_bustraces_g-1) of bustrace_t;
  --signal selected_bustrace : bustrace_t;
  signal bustraces_arr : bustraces_arr_t;


begin

  divide_traces: for i in 0 to nof_bustraces_g-1 generate
    bustraces_arr(i) <= bustraces((i+1)*data_width_g-1 downto i*data_width_g);
  end generate;

  -----------------------------------------------------------------------------
  -- interrupt generation
  -- assert irq line if unmasked flag is set or breakpoint has been hit
  -----------------------------------------------------------------------------
  irqgen : process(clk, nreset)
  begin
    if (nreset = '0') then
      irq <= '0';
    elsif rising_edge(clk) then
      irq <= '0';
      if ( (dbcontrol(TTA_IRQMASK) and dbstatus(TTA_FLAGS)) /=
           std_logic_vector(to_unsigned(0, data_width_g))
        or (dbstatus(TTA_STATUS)(debreg_nof_breakpoints_c-1 downto 0) /=
            std_logic_vector(to_unsigned(0, debreg_nof_breakpoints_c)))) then
        irq <= '1';
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Debugger configuration and command outputs
  --
  -- - NOTE: special handling for continue and force break -bits
  --         (bypassed as pulse)
  -----------------------------------------------------------------------------
  tta_continue_pass : process(clk, nreset)
  begin
    if (nreset = '0') then
      tta_continue <= '0';
      tta_forcebreak <= '0';
      icache_invalidate <= '0';
      dcache_invalidate <= '0';
    elsif rising_edge(clk) then
      tta_continue <= '0';
      tta_forcebreak <= '0';
      icache_invalidate <= '0';
      dcache_invalidate <= '0';
      if (ctrl_we(TTA_DEBUG_CMD) = '1') then
        tta_continue <= din_if(DEBUG_CMD_CONTINUE);
        tta_forcebreak <= din_if(DEBUG_CMD_BREAK);
        icache_invalidate <= din_if(DEBUG_CMD_INVALIDATE_ICACHE);
        dcache_invalidate <= din_if(DEBUG_CMD_INVALIDATE_DCACHE);
      end if;
    end if;
  end process;

  pc_start_address <= dbcontrol(TTA_PC_START)(pc_width_c-1 downto 0);
  bp0              <= dbcontrol(TTA_DEBUG_BP0);
  bp0_type         <= dbcontrol(TTA_DEBUG_CTRL)(1 downto 0);
  bp1              <= dbcontrol(TTA_DEBUG_BP1)(pc_width_c-1 downto 0);
  bp2              <= dbcontrol(TTA_DEBUG_BP2)(pc_width_c-1 downto 0);
  --bp3              <= dbcontrol(TTA_DEBUG_BP3)(pc_width_c-1 downto 0);
  --bp4              <= dbcontrol(TTA_DEBUG_BP4)(pc_width_c-1 downto 0);
  bp_enable        <= dbcontrol(TTA_DEBUG_CTRL)(5 downto 2);
  tta_reset        <= dbcontrol(TTA_DEBUG_CMD)(0);
  imem_page        <= dbcontrol(TTA_IMEM_PAGE);
  imem_mask        <= dbcontrol(TTA_IMEM_MASK);
  dmem_page        <= dbcontrol(TTA_DMEM_PAGE);
  dmem_mask        <= dbcontrol(TTA_DMEM_MASK);

  -----------------------------------------------------------------------------
  -- ctrl register write encoder
  -- when incoming write enable is asserted, forward it to the
  -- correct control register
  -- Inputs:  we_if        debugger global write enable
  --          addr_if      write address
  -- outputs: ctrl_we      register-wise write enables
  -----------------------------------------------------------------------------
  write_encoded : process(we_if, addr_if)
    variable cregix : integer range 2**(addr_width_g-1)-1 downto 0;
    -- normalized we-vector (index starts from 0).
    -- Note: directrion (0 to ...) compatible with register addressing.
    variable ctrl_we_0 : std_logic_vector(0 to nof_control_registers_c-1);
  begin
    ctrl_we <= (others => '0');
    if (we_if = '1') then
      if (addr_if(addr_width_g-1) = '1') then
        cregix := to_integer(unsigned(addr_if(addr_width_g-2 downto 0)));
        --pragma translate_off
        assert (cregix < nof_control_registers_c)
          report "Write request to non-existing control register"
             & ", cregix=" & integer'image(cregix)
             & ", #ctrl regs=" & integer'image(nof_control_registers_c)
          severity error;
        --pragma translate_on
        if (cregix < nof_control_registers_c) then
          ctrl_we_0 := (others => '0');
          ctrl_we_0(cregix) := '1';
          ctrl_we <= ctrl_we_0;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- read address encoding
  -----------------------------------------------------------------------------
  read_encoder : process(clk, nreset)
    variable regix : unsigned(addr_width_g-2 downto 0);
    variable btix  : integer range 2**(addr_width_g-1) downto 0;
  begin
    if (nreset = '0') then
      dout_if <= (others => '0');
      stdout_read <= '0';
      --selected_bustrace <= (others => '0');
    elsif rising_edge(clk) then
      dout_if <= (others => '0');
      stdout_read <= '0';
      --selected_bustrace <= (others => '0');

      -- return tta info
      if (re_if = '1') then
        if (unsigned(addr_if) = to_unsigned(TTA_DMEM_SIZE, 8)) then
          dout_if <= std_logic_vector(to_unsigned(debinfo_dmem_size_c, data_width_g));
        elsif (unsigned(addr_if) = to_unsigned(TTA_PMEM_SIZE, 8)) then
          dout_if <= std_logic_vector(to_unsigned(debinfo_pmem_size_c, data_width_g));
        elsif (unsigned(addr_if) = to_unsigned(TTA_IMEM_SIZE, 8)) then
          dout_if <= std_logic_vector(to_unsigned(debinfo_imem_size_c, data_width_g));
        elsif (unsigned(addr_if) = to_unsigned(TTA_DEVICECLASS, 8)) then
          dout_if <= std_logic_vector(to_unsigned(debinfo_deviceclass_c, data_width_g));
        elsif (unsigned(addr_if) = to_unsigned(TTA_DEVICE_ID, 8)) then
          dout_if <= std_logic_vector(to_unsigned(debinfo_device_id_c, data_width_g));
        elsif (unsigned(addr_if) = to_unsigned(TTA_INTERFACE_TYPE, 8)) then
          dout_if <= std_logic_vector(to_unsigned(debinfo_interface_type_c, data_width_g));
        else  
          regix := unsigned(addr_if(addr_width_g-2 downto 0));
          --status register read access
          if (addr_if(addr_width_g-1) = '0') then
            if (to_integer(regix) <= nof_status_registers_c-1) then
              dout_if <= dbstatus(to_integer(regix));
              if (to_integer(regix) = TTA_STDOUT_D) then
                stdout_read <= '1';
              end if;
            -- bus trace
            elsif (to_integer(regix) > 15) then
              btix := to_integer(regix)-16;
              if (btix < nof_bustraces_g) then
                dout_if <= bustraces_arr(btix);
              else
                --pragma translate_off
                assert (false)
                  report "Invalid bus trace index: " & integer'image(btix)
                  severity error;
              --pragma translate_on
              end if;
            end if;
          -- control register read access
          else
            if (to_integer(regix) < nof_control_registers_c) then
              dout_if <= dbcontrol(to_integer(regix)+control_addresspace_start_c);
            else
              assert (false)
                report "Non-exiting control register read access"
                severity error;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Status registers:
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- TTA_STATUS
  -----------------------------------------------------------------------------
  din_tta_status <= bp_hit(4 downto 3) & stdout_pending & bp_hit(2 downto 0);
  sreg_tta_status : entity work.status_register
    generic map (reg_width_g    => status_registers_c(TTA_STATUS).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_tta_status,
              dout   => dbstatus(TTA_STATUS)
             );

  -----------------------------------------------------------------------------
  -- TTA_PC
  -----------------------------------------------------------------------------
  sreg_tta_pc : entity work.status_register
    generic map (reg_width_g => status_registers_c(TTA_PC).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => pc,
              dout   => dbstatus(TTA_PC)
              );

  -----------------------------------------------------------------------------
  -- TTA_CYCLECNT
  -----------------------------------------------------------------------------
  sreg_tta_cyclecnt : entity work.status_register
    generic map (reg_width_g => status_registers_c(TTA_CYCLECNT).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => cycle_cnt,
              dout   => dbstatus(TTA_CYCLECNT)
              );

  -----------------------------------------------------------------------------
  -- AXI performance counters
  -----------------------------------------------------------------------------
  gen_perfcounters : for i in 0 to 2 generate
    perfcnt : entity work.status_register
    generic map (reg_width_g => status_registers_c(AXI_RD0_BURSTCNT+i).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => axi_burst_cnt((i+1)*data_width_g-1
                                      downto i*data_width_g),
              dout   => dbstatus(AXI_RD0_BURSTCNT+i)
              );
  end generate;

  -----------------------------------------------------------------------------
  -- AXI error counters
  -----------------------------------------------------------------------------
  gen_errcounters : for i in 0 to 2 generate
    errcnt : entity work.status_register
    generic map (reg_width_g => status_registers_c(AXI_RD0_ERRCNT+i).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => axi_err_cnt((i+1)*data_width_g-1 downto i*data_width_g),
              dout   => dbstatus(AXI_RD0_ERRCNT+i)
              );
  end generate;

  -----------------------------------------------------------------------------
  -- TTA_LOCKCNT
  -----------------------------------------------------------------------------
  sreg_tta_lockcnt : entity work.status_register
    generic map (reg_width_g => status_registers_c(TTA_LOCKCNT).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => lock_cnt,
              dout   => dbstatus(TTA_LOCKCNT)
              );


  -----------------------------------------------------------------------------
  -- TTA_FLAGS
  -----------------------------------------------------------------------------
  sreg_tta_flags : entity work.status_register
    generic map (reg_width_g => status_registers_c(TTA_FLAGS).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => flags,
              dout   => dbstatus(TTA_FLAGS)
              );

  -----------------------------------------------------------------------------
  -- TTA_STDOUT_D
  -----------------------------------------------------------------------------
  sreg_stdout_d : entity work.status_register
    generic map (reg_width_g => status_registers_c(TTA_STDOUT_D).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => stdout_d,
              dout   => dbstatus(TTA_STDOUT_D)
              );

  -----------------------------------------------------------------------------
  -- TTA_STDOUT_N
  -----------------------------------------------------------------------------
  sreg_stdout_n : entity work.status_register
    generic map (reg_width_g => status_registers_c(TTA_STDOUT_N).bits,
                 output_width_g => data_width_g
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => stdout_n,
              dout   => dbstatus(TTA_STDOUT_N)
              );
  

  -----------------------------------------------------------------------------
  -- TTA bus trace
  -----------------------------------------------------------------------------
  --sreg_tta_bustrafe : for i in 0 to nof_bustraces_g-1 generate
    --bustrace_reg : status_register
    --  generic map (reg_width_g => bustrace_width_c,
    --               output_width_g => data_width_g
    --               )
    --  port map (clk    => clk,
    --            nreset => nreset,
    --            --din    => bustrace((i+1)*bustrace_width_c-1 downto
    --            --                   i*bustrace_width_c),
    --            din    => selected_bustrace,
    --            dout   => dbstatus(nof_status_registers_c)
    --            );

  -----------------------------------------------------------------------------
  -- Control Registers:
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- TA_PC_START
  -----------------------------------------------------------------------------
  creg_tta_pc_start : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_PC_START).bits,
                 output_width_g => data_width_g,
                 reset_val_g    => 0
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_PC_START).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_PC_START),
              we     => ctrl_we(TTA_PC_START)
              );

  -----------------------------------------------------------------------------
  -- TA_DEBUG_BP0
  -----------------------------------------------------------------------------
  creg_tta_debug_bp0 : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_DEBUG_BP0).bits,
                 output_width_g => data_width_g,
                 reset_val_g    => 0
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_DEBUG_BP0).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_DEBUG_BP0),
              we     => ctrl_we(TTA_DEBUG_BP0)
              );

  -----------------------------------------------------------------------------
  -- TTA_DEBUG_BP1...BP4
  -- Note: indexing started from 1 to maintain instance name coherency
  -----------------------------------------------------------------------------
  creg_tta_debug_bpn : for i in 1 to 2 generate
    debug_bpn_reg : entity work.control_register
      generic map (reg_width_g => control_registers_c(TTA_DEBUG_BP1-1+i).bits,
                   output_width_g => data_width_g,
                   reset_val_g    => 0
                   )
      port map (clk    => clk,
                nreset => nreset,
                din    => din_if(control_registers_c(TTA_DEBUG_BP1-1+i).bits-1
                                 downto 0),
                dout   => dbcontrol(TTA_DEBUG_BP1-1+i),
                we     => ctrl_we(TTA_DEBUG_BP1-1+i)
                );
    end generate;

  -----------------------------------------------------------------------------
  -- TTA_DEBUG_CTRL
  -----------------------------------------------------------------------------
  creg_tta_debug_ctrl : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_DEBUG_CTRL).bits,
                 output_width_g => data_width_g,
                 reset_val_g    => 0
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_DEBUG_CTRL).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_DEBUG_CTRL),
              we     => ctrl_we(TTA_DEBUG_CTRL)
              );

  -----------------------------------------------------------------------------
  -- TTA_DEBUG_CMD
  -----------------------------------------------------------------------------
  creg_tta_debug_cmd : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_DEBUG_CMD).bits,
                 output_width_g => data_width_g,
                 reset_val_g => 1
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_DEBUG_CMD).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_DEBUG_CMD),
              we     => ctrl_we(TTA_DEBUG_CMD)
              );

  -----------------------------------------------------------------------------
  -- TTA_IRQMASK
  -----------------------------------------------------------------------------
  creg_tta_irqmask : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_IRQMASK).bits,
                 output_width_g => data_width_g,
                 reset_val_g    => 0
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_IRQMASK).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_IRQMASK),
              we     => ctrl_we(TTA_IRQMASK)
              );

  -----------------------------------------------------------------------------
  -- TTA_IMEM_PAGE
  -----------------------------------------------------------------------------
  creg_tta_imem_page : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_IMEM_PAGE).bits,
                 output_width_g => data_width_g,
                 reset_val_g    => 0
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_IMEM_PAGE).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_IMEM_PAGE),
              we     => ctrl_we(TTA_IMEM_PAGE)
              );

  -----------------------------------------------------------------------------
  -- TTA_IMEM_MASK
  -----------------------------------------------------------------------------
  creg_tta_imem_mask : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_IMEM_MASK).bits,
                 output_width_g => data_width_g,
                 reset_val_g    => 0
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_IMEM_MASK).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_IMEM_MASK),
              we     => ctrl_we(TTA_IMEM_MASK)
              );
  
  -----------------------------------------------------------------------------
  -- TTA_DMEM_PAGE
  -----------------------------------------------------------------------------
  creg_tta_dmem_page : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_DMEM_PAGE).bits,
                 output_width_g => data_width_g,
                 reset_val_g    => 1
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_DMEM_PAGE).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_DMEM_PAGE),
              we     => ctrl_we(TTA_DMEM_PAGE)
              );

  -----------------------------------------------------------------------------
  -- TTA_DMEM_MASK
  -----------------------------------------------------------------------------
  creg_tta_dmem_mask : entity work.control_register
    generic map (reg_width_g => control_registers_c(TTA_DMEM_MASK).bits,
                 output_width_g => data_width_g,
                 reset_val_g    => 0
                 )
    port map (clk    => clk,
              nreset => nreset,
              din    => din_if(control_registers_c(TTA_DMEM_MASK).bits-1
                               downto 0),
              dout   => dbcontrol(TTA_DMEM_MASK),
              we     => ctrl_we(TTA_DMEM_MASK)
              );
  

end rtl;
