-- Copyright (c) 2016 Tampere University of Technology
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
-----------------------------------------------------------------------------
-- Title      : Example ALMARVI interface TTA 
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tta-accel-entity.vhdl
-- Author     : Viitanen Timo (Tampere University of Technology)  <timo.2.viitanen@tut.fi>
-- Company    : 
-- Created    : 2016-01-27
-- Last update: 2016-01-27
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-01-27  1.0      viitanet Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
--use work.axi4_pkg.all;

-- TTA memory interfaces
use work.tta0_globals.all;
use work.tta0_params.all;
use work.tta0_imem_mau.all;

entity tta_accel is
  generic (
    io_addrw_g : integer;
    io_dataw_g : integer
  );
  port (
    clk        : in  std_logic;
    nreset     : in  std_logic;
    --
    io_addr    : in  std_logic_vector(io_addrw_g-1 downto 0);
    io_wr_data : in  std_logic_vector(io_dataw_g-1 downto 0);
    io_wr_mask : in  std_logic_vector(io_dataw_g/8-1 downto 0);
    io_rd_data : out std_logic_vector(io_dataw_g-1 downto 0);
    io_rd_en   : in  std_logic;
    io_wr_en   : in  std_logic
  );
end entity tta_accel;
