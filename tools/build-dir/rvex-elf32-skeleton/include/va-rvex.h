/* This file has been modified or added by STMicroelectronics, Inc. 1999-2007 */

#ifndef __VA_RVEX_H__
#define __VA_RVEX_H__


/* 
 * Embedded LibC, Host Support
 *
 * Copyright 2001-2002, STMicroelectronics, Inc. All Rights Reserved. 
 *
 * Maybe instanciated as:
 *  + [ST220 host support]
 *
 * This file is derived from st220-libhost.src
 * ($Revision: 1.30.2.3 $ $Date: 2006/03/08 17:21:48 $)
 *
*/


/* GNU C varargs and stdargs support for the ST200. 
   Christian Bruel <christian.bruel@st.com>
   $Id: st220-libhost.src,v 1.30.2.3 2006/03/08 17:21:48 clarkes Exp $
*/

/* Define __gnuc_va_list.  */

#ifndef __GNUC_VA_LIST
#define __GNUC_VA_LIST
typedef __builtin_va_list __gnuc_va_list;
#endif

/* If this is for internal libc use, don't define anything but
   __gnuc_va_list.  */
#if defined (_STDARG_H) || defined (_VARARGS_H)

#define __va_ellipsis ...

/* These macros implement traditional (non-ANSI) varargs
   for GNU C.  */

#define va_alist  __builtin_va_alist
/* The ... causes current_function_varargs to be set in cc1.  */
/* ??? We don't process attributes correctly in K&R argument context.*/
typedef int __builtin_va_alist_t __attribute__((__mode__(__word__)));
#define va_dcl  __builtin_va_alist_t __builtin_va_alist; __va_ellipsis

#ifdef _STDARG_H

#define va_start(list, argN) __builtin_va_start((list),(argN))
#define va_arg(list,type)    __builtin_va_arg(list,type)
#define va_end(list) ((void)0)
#endif

/* Copy __gnuc_va_list into another variable of this type.  */
#define __va_copy(dest, src) (dest) = (src)
#define va_copy __va_copy

#endif /* defined (_STDARG_H) || defined (_VARARGS_H) */

/*
  Caveat: this fragment is dependant on srccode include guards management
  In this very specific case, wich is to use this file in specific contexts
  (typically Newlibc) we shall not be guarded against multiple inclusions.
*/
#if defined __VA_RVEX_H__
#undef __VA_RVEX_H__
#else
#error "Error in <va-rvex.h> : __VA_RVEX_H__ expected to be defined at this point"
#endif


#endif /*__VA_RVEX_H__*/
