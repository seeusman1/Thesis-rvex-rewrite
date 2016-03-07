# Determine absolute path to this script.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Figure out toolchain paths.
O64=$DIR/..
RVRW=$DIR/../../rvex-rewrite

# Toolchain binaries.
CC=$O64/open64_8issue_16UNROLL/bin/st200-gcc
AS=$O64/rvex-elf32-32bit/bin/rvex-elf32-as
LD=$O64/rvex-elf32-32bit/bin/rvex-elf32-ld
CFLAGS=""
ASFLAGS=""
LDFLAGS=""

# Include newlib stuff.
# TODO
#CFLAGS+="-mlibdir=/data/uCLinux/generic_binary/uCLinux/uClibc/lib"

# Include path for C-library and compiler internal headers.
CFLAGS+="-I$O64/ST200R7.3.0/include "
CFLAGS+="-I$O64/ST200R7.3.0/target/core/st220 "

# rvex configuration and platform specifics.
CFLAGS+="-I$RVRW/examples/src "
CFLAGS+="-I$RVRW/platform/ml605-grlib/examples/src "
ASFLAGS+="-Wa,--issue,8,--borrow,1.0.3.2.5.4.7.6.,--config,fbfbfbfb,-u,--autosplit,--padding=2 "

# Magic stuff.
CFLAGS+="-O3 -CG:LAO_activation=0 -Wall -Wstrict-prototypes -fomit-frame-pointer "
CFLAGS+="-fno-strength-reduce -mcore=st220 -EB -nostdlib --no-deadcode --icache-opt=off "
CFLAGS+="-fshort-double  -fno-dismissible-load -fno-exceptions -mno-auto-prefetch "
CFLAGS+="--no-relax -OPT:unroll_size=128 -OPT:unroll_times_max=32 -CG:nop2goto=0 "
ASFLAGS+="-Ya,$O64/open64_8issue_16UNROLL/bin "
LDFLAGS+="-Yl,$O64/open64_8issue_16UNROLL/bin -Wl,-q,-x"


#LDFLAGS+=",-L,/data/uCLinux/generic_binary/uCLinux/uClibc/lib,"
#LDFLAGS+="-L,/data/uCLinux/generic_binary/uCLinux/user/mandelbrot/IFR8_stat/LIBFP,"
#LDFLAGS+="/data/uCLinux/generic_binary/uCLinux/uClibc/lib/crt0.o,"
#LDFLAGS+="/data/uCLinux/generic_binary/uCLinux/linux-2.0.x/arch/VEX/lib/VEXdiv.o,"
#LDFLAGS+="-lcfpi-st220.cc,-lc"

gcc_func() {
    #echo -e "\e[1;31m$CC $@ \e[0;31m$CFLAGS $ASFLAGS $LDFLAGS\e[0m"
    $CC $@ $CFLAGS $ASFLAGS $LDFLAGS
}
gcc_func "$@"

