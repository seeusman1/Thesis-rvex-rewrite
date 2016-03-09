library ieee;
use ieee.std_logic_1164.all;

package misc is
  function sel_cond(cond : boolean; a,b : integer) return integer;

  function mmax (a,b : integer) return integer;

end misc;

package body misc is

  function sel_cond(cond : boolean; a,b : integer) return integer is
  begin
    if (cond = true) then return a; else return b; end if;
  end sel_cond;

  function mmax (a,b : integer) return integer is
  begin
    if (a > b) then return a; else return b; end if;
  end mmax;

end misc;