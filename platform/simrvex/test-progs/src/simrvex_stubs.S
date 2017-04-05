

sim_exit::
	/* Shuffle the arguments */
	mov	$r0.4 = $r0.3
	mov	$r0.3 = 1
	;;
	trap 0x91
	;;
	return $l0.0
	;;

/*
 * The parameter is a bitfield
 * TRACE_OFF             0
 * TRACE_USER_MODE       1
 * TRACE_SUPER_MODE      2
 * TRACE_ON  (TRACE_USER_MODE|TRACE_SUPER_MODE)
*/

sim_trace::
	mov	$r0.2 = 217
	;;
	trap 0x91
	;;
	return $l0.0
	;;

sim_write::
	/* Shuffle the arguments */
	mov	$r0.2 = 4
	;;
	trap 0x91
	;;
	return $l0.0
	;;

