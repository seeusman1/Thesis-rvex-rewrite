library IEEE;
use IEEE.std_logic_1164.all;

-- If you're seeing this file, I was too lazy to remove it in the release.
-- Shame on me.
--
--            .---------------------------------------------------.
--            | rv                                                |
--            | .---------------------------------------.         |
--            | | pls (pipelanes)                       |         |
--            | |  .=================================.  | .-----. |
--            | |  | pl (pipelane)                   |  | |gpreg| |
--            | |  |  - . .---.  - - .  - - .  - - . |  | |.---.| |
--  imem <----+-+->| |br  |alu| |mulu  |memu  |brku  |<-+>||fwd|| |
--            | |  |  - ' '---'  - - '  - - '  - - ' |  | |'---'| |
--            | |  '================================='  | '-----' |
--            | |    ^             ^       ^      ^     |         |
--            | |    |             |       |      |     |         |
--            | |    v             v       v      v     |         |
--            | | .------.       .====.  .----. .----.  |         |
--          .-+-+>|cxplif|       |dmsw|  |trap| |limm|  |         |
--          | | | '------'       '===='  '----' '----'  |         |
--          | | |    ^            ^  ^                  |         |
--          | | |    |            |  '------------------+---------+--> dmem
-- rctrl <-<  | '----+------------+---------------------'         |
--          | |      v            v                               |
--          | |   .=====.      .----.      .-----.      .-----.   |
--          | |   |cxreg|<---->|creg|<---->|gbreg|<---->|     |<--+--> mem
--          '-+-->|.---.|      '----'      '-----'      | cfg |   |
--            |   ||fwd||         ^           ^   ...<--|     |   |
--            |   |'---'|---------+-----------+-------->|     |   |
--            |   '====='         |           |         '-----'   |
--            '-------------------+-----------+-------------------'
--                                |           |
--                                v           |
--                               dbg    imem affinity
--
--
-- Entity TODO list:
-- [.] rv     = RVex processor             @ rvex.vhd
-- [?] pls    = PipeLaneS                  @ rvex_pipelanes.vhd
-- [x] pl     = PipeLane                   @ rvex_pipelane.vhd
-- [x] br     = BRanch unit                @ rvex_branch.vhd
-- [x] alu    = Arith. Logic Unit          @ rvex_alu.vhd
-- [x] memu   = MEMory Unit                @ rvex_memu.vhd
-- [.] mulu   = MULtiply Unit              @ rvex_mul.vhd
-- [x] brku   = BReaKpoint Unit            @ rvex_breakpoint.vhd
-- [ ] gpreg  = General Purpose REGisters  @ rvex_gpreg.vhd
-- [?] fwd    = ForWarDing logic           @ rvex_forward.vhd
-- [?] cxplif = ConteXt Register InterFace @ rvex_contextPipelaneIFace.vhd
-- [x] dmsw   = Data Memory SWitch         @ rvex_dmemSwitch.vhd
-- [x] limm   = Long IMMediate routing     @ rvex_limmRouting.vhd
-- [x] trap   = TRAP routing               @ rvex_trapRouting.vhd
-- [?] cxreg  = ConteXt REGister logic     @ rvex_contextRegLogic.vhd
-- [?] creg   = Control REGisters          @ rvex_ctrlRegs.vhd
-- [ ] gbreg  = GloBal REGister logic      @ rvex_globalRegLogic.vhd
-- [?] cfg    = ConFiGuration control      @ rvex_cfgCtrl.vhd
--
-- Key for the entity TODO list:
-- [ ] = nothing done
-- [?] = some work is done, but it's out of date
-- [.] = entity done
-- [x] = architecture done

entity todo is
end todo;

architecture Behavioral of todo is
begin
end Behavioral;

