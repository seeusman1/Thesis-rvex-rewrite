/* -- This file is automatically generated -- */ 
/* 

  Copyright (C) 2002, 2004 ST Microelectronics, Inc.  All Rights Reserved. 

  This program is free software; you can redistribute it and/or modify it 
  under the terms of version 2 of the GNU General Public License as 
  published by the Free Software Foundation. 
  This program is distributed in the hope that it would be useful, but 
  WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 

  Further, this software is distributed without any warranty that it is 
  free of the rightful claim of any third person regarding infringement 
  or the like.  Any license provided herein, whether implied or 
  otherwise, applies only to this software file.  Patent licenses, if 
  any, provided herein do not apply to combinations of this program with 
  other software, or any other product whatsoever. 
  You should have received a copy of the GNU General Public License along 
  with this program; if not, write the Free Software Foundation, Inc., 59 
  Temple Place - Suite 330, Boston MA 02111-1307, USA. 

  Contact information:  ST Microelectronics, Inc., 
  , or: 

  http://www.st.com 

  For further information regarding this notice, see: 

  http: 
*/ 

// AUTOMATICALLY GENERATED FROM MDS DATA BASE !!! 
//  st220 processor scheduling information 
///////////////////////////////////// 
//   
//  Description:  
//  
//  Generate a scheduling description of a st220 processor  
//  via the si_gen interface.  
//  
/////////////////////////////////////  

#include "si_gen.h" 
#include "targ_isa_subset.h" 
#include "topcode.h" 

/*
 * When compiling for a longer pipeline (with forwarding), set this to whatever amount of extra cycles you need
 */
#define EXTRA_LATENCY   0

/*
 * If forwarding is disabled, all operations have the same result available time.
 * This file uses cycle 1 as the Operand_Access_Time for all instructions.
 * However, the actual access time is the GPREAD stage.
 * So we first calculate the difference between those 2 and subtract that 
 * from the WB stage.
 */
//#define FORWARDING_DISABLED
#ifdef FORWARDING_DISABLED
#define HW_GPREAD_STAGE 2
#define HW_WB_STAGE     5
#define READSTAGE_DIFF  (HW_GPREAD_STAGE-1)
#define WB_STAGE        (HW_WB_STAGE-READSTAGE_DIFF)
#endif

int 
main (int argc, char *argv[]) 
{ 
  RESOURCE Resource_st220_ISSUE = RESOURCE_Create("Resource_st220_ISSUE", 4);
  RESOURCE Resource_st220_MEM = RESOURCE_Create("Resource_st220_MEM", 1);
  RESOURCE Resource_st220_CTL = RESOURCE_Create("Resource_st220_CTL", 1);
  RESOURCE Resource_st220_ODD = RESOURCE_Create("Resource_st220_ODD", 4);
  RESOURCE Resource_st220_EVEN = RESOURCE_Create("Resource_st220_EVEN", 2);
  RESOURCE Resource_st220_LANE0 = RESOURCE_Create("Resource_st220_LANE0", 2);

  /* ======================================================
   * Resource description for the ISA_SUBSET_st220
   * ======================================================
   */

  Machine("rvex", ISA_SUBSET_rvex, argc, argv);

  Instruction_Group("group0",
		TOP_brf_i_b,
		TOP_br_i_b,
		TOP_UNDEFINED);

  Operand_Access_Time (0, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_CTL, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group1",
		TOP_igoto,
		TOP_return,
		TOP_UNDEFINED);

  Operand_Access_Time (0, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_CTL, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group2",
		TOP_stb_r_r_ii,
		TOP_sth_r_r_ii,
		TOP_stw_r_r_ii,
		TOP_UNDEFINED);

  Operand_Access_Time (1, 1);
  Operand_Access_Time (2, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_MEM, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group3",
		TOP_stb_r_r_i,
		TOP_sth_r_r_i,
		TOP_stw_r_r_i,
		TOP_UNDEFINED);

  Operand_Access_Time (1, 1);
  Operand_Access_Time (2, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_MEM, 0);


  Instruction_Group("group4",
		TOP_pft_r_ii,
		TOP_prgadd_r_ii,
		TOP_prgset_r_ii,
		TOP_UNDEFINED);

  Operand_Access_Time (1, 2);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_MEM, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group5",
		TOP_pft_r_i,
		TOP_prgadd_r_i,
		TOP_prgset_r_i,
		TOP_UNDEFINED);

  Operand_Access_Time (1, 2);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_MEM, 0);


  Instruction_Group("group6",
		TOP_break,
		TOP_nop,
		TOP_sbrk_i,
		TOP_UNDEFINED);

  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group7",
		TOP_goto_i,
		TOP_rfi,
		TOP_syncins,
		TOP_UNDEFINED);

  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_CTL, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group8",
		TOP_asm,
		TOP_prgins,
		TOP_syscall_i,
		TOP_UNDEFINED);

  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group9",
		TOP_sync,
		TOP_UNDEFINED);

  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_MEM, 0);



  Instruction_Group("group10",
		TOP_icall,
		TOP_UNDEFINED);
#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_CTL, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group11",
		TOP_slctf_r_r_b_r,
		TOP_slct_r_r_b_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Operand_Access_Time (1, 1);
  Operand_Access_Time (2, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group12",
		TOP_add_r_r_r,
		TOP_andc_r_r_r,
		TOP_andl_r_r_b,
		TOP_andl_r_r_r,
		TOP_and_r_r_r,
		TOP_asm_0_r_r_r,
		TOP_asm_1_r_r_r,
		TOP_asm_2_r_r_r,
		TOP_asm_3_r_r_r,
		TOP_asm_4_r_r_r,
		TOP_asm_5_r_r_r,
		TOP_asm_6_r_r_r,
		TOP_asm_7_r_r_r,
		TOP_cmpeq_r_r_b,
		TOP_cmpeq_r_r_r,
		TOP_cmpgeu_r_r_b,
		TOP_cmpgeu_r_r_r,
		TOP_cmpge_r_r_b,
		TOP_cmpge_r_r_r,
		TOP_cmpgtu_r_r_b,
		TOP_cmpgtu_r_r_r,
		TOP_cmpgt_r_r_b,
		TOP_cmpgt_r_r_r,
		TOP_cmpleu_r_r_b,
		TOP_cmpleu_r_r_r,
		TOP_cmple_r_r_b,
		TOP_cmple_r_r_r,
		TOP_cmpltu_r_r_b,
		TOP_cmpltu_r_r_r,
		TOP_cmplt_r_r_b,
		TOP_cmplt_r_r_r,
		TOP_cmpne_r_r_b,
		TOP_cmpne_r_r_r,
		TOP_maxu_r_r_r,
		TOP_max_r_r_r,
		TOP_minu_r_r_r,
		TOP_min_r_r_r,
		TOP_nandl_r_r_b,
		TOP_nandl_r_r_r,
		TOP_norl_r_r_b,
		TOP_norl_r_r_r,
		TOP_orc_r_r_r,
		TOP_orl_r_r_b,
		TOP_orl_r_r_r,
		TOP_or_r_r_r,
		TOP_sh1add_r_r_r,
		TOP_sh2add_r_r_r,
		TOP_sh3add_r_r_r,
		TOP_sh4add_r_r_r,
		TOP_shl_r_r_r,
		TOP_shru_r_r_r,
		TOP_shr_r_r_r,
		TOP_slctf_i_r_b_r,
		TOP_slct_i_r_b_r,
		TOP_sub_r_r_r,
		TOP_xor_r_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Operand_Access_Time (1, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group13",
		TOP_slctf_ii_r_b_r,
		TOP_slct_ii_r_b_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Operand_Access_Time (1, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group14",
		TOP_add_i_r_r,
		TOP_spadjust,
		TOP_andc_i_r_r,
		TOP_andl_i_r_b,
		TOP_andl_i_r_r,
		TOP_and_i_r_r,
		TOP_asm_16_i_r_r,
		TOP_asm_17_i_r_r,
		TOP_asm_18_i_r_r,
		TOP_asm_19_i_r_r,
		TOP_asm_20_i_r_r,
		TOP_asm_21_i_r_r,
		TOP_asm_22_i_r_r,
		TOP_asm_23_i_r_r,
		TOP_bswap_r_r,
		TOP_clz_r_r,
		TOP_cmpeq_i_r_b,
		TOP_cmpeq_i_r_r,
		TOP_cmpgeu_i_r_b,
		TOP_cmpgeu_i_r_r,
		TOP_cmpge_i_r_b,
		TOP_cmpge_i_r_r,
		TOP_cmpgtu_i_r_b,
		TOP_cmpgtu_i_r_r,
		TOP_cmpgt_i_r_b,
		TOP_cmpgt_i_r_r,
		TOP_cmpleu_i_r_b,
		TOP_cmpleu_i_r_r,
		TOP_cmple_i_r_b,
		TOP_cmple_i_r_r,
		TOP_cmpltu_i_r_b,
		TOP_cmpltu_i_r_r,
		TOP_cmplt_i_r_b,
		TOP_cmplt_i_r_r,
		TOP_cmpne_i_r_b,
		TOP_cmpne_i_r_r,
		TOP_convbi_b_r,
		TOP_convib_r_b,
		TOP_maxu_i_r_r,
		TOP_max_i_r_r,
		TOP_mfb_b_r,
		TOP_minu_i_r_r,
		TOP_min_i_r_r,
		TOP_mov_r_r,
		TOP_mov_r_b,
		TOP_mov_b_r,
		TOP_mtb_r_b,
		TOP_nandl_i_r_b,
		TOP_nandl_i_r_r,
		TOP_norl_i_r_b,
		TOP_norl_i_r_r,
		TOP_orc_i_r_r,
		TOP_orl_i_r_b,
		TOP_orl_i_r_r,
		TOP_or_i_r_r,
		TOP_sh1add_i_r_r,
		TOP_sh2add_i_r_r,
		TOP_sh3add_i_r_r,
		TOP_sh4add_i_r_r,
		TOP_shl_i_r_r,
		TOP_shru_i_r_r,
		TOP_shr_i_r_r,
		TOP_sxtb_r_r,
		TOP_sxth_r_r,
		TOP_xor_i_r_r,
		TOP_zxtb_r_r,
		TOP_zxth_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group15",
		TOP_add_ii_r_r,
		TOP_andc_ii_r_r,
		TOP_andl_ii_r_b,
		TOP_andl_ii_r_r,
		TOP_and_ii_r_r,
		TOP_asm_16_ii_r_r,
		TOP_asm_17_ii_r_r,
		TOP_asm_18_ii_r_r,
		TOP_asm_19_ii_r_r,
		TOP_asm_20_ii_r_r,
		TOP_asm_21_ii_r_r,
		TOP_asm_22_ii_r_r,
		TOP_asm_23_ii_r_r,
		TOP_cmpeq_ii_r_b,
		TOP_cmpeq_ii_r_r,
		TOP_cmpgeu_ii_r_b,
		TOP_cmpgeu_ii_r_r,
		TOP_cmpge_ii_r_b,
		TOP_cmpge_ii_r_r,
		TOP_cmpgtu_ii_r_b,
		TOP_cmpgtu_ii_r_r,
		TOP_cmpgt_ii_r_b,
		TOP_cmpgt_ii_r_r,
		TOP_cmpleu_ii_r_b,
		TOP_cmpleu_ii_r_r,
		TOP_cmple_ii_r_b,
		TOP_cmple_ii_r_r,
		TOP_cmpltu_ii_r_b,
		TOP_cmpltu_ii_r_r,
		TOP_cmplt_ii_r_b,
		TOP_cmplt_ii_r_r,
		TOP_cmpne_ii_r_b,
		TOP_cmpne_ii_r_r,
		TOP_maxu_ii_r_r,
		TOP_max_ii_r_r,
		TOP_minu_ii_r_r,
		TOP_min_ii_r_r,
		TOP_nandl_ii_r_b,
		TOP_nandl_ii_r_r,
		TOP_norl_ii_r_b,
		TOP_norl_ii_r_r,
		TOP_orc_ii_r_r,
		TOP_orl_ii_r_b,
		TOP_orl_ii_r_r,
		TOP_or_ii_r_r,
		TOP_sh1add_ii_r_r,
		TOP_sh2add_ii_r_r,
		TOP_sh3add_ii_r_r,
		TOP_sh4add_ii_r_r,
		TOP_shl_ii_r_r,
		TOP_shru_ii_r_r,
		TOP_shr_ii_r_r,
		TOP_xor_ii_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group16",
		TOP_sub_r_i_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (1, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group17",
		TOP_sub_r_ii_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (1, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group18",
		TOP_mov_i_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group19",
		TOP_call_i,
		TOP_getpc,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_CTL, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group20",
		TOP_mov_ii_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
#endif
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group21",
		TOP_addcg_b_r_r_b_r,
		TOP_divs_b_r_r_b_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
  Result_Available_Time (1, WB_STAGE);
#else
  Result_Available_Time (0, 2 + EXTRA_LATENCY);
  Result_Available_Time (1, 2 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Operand_Access_Time (1, 1);
  Operand_Access_Time (2, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group22",
		TOP_pushregs,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
  Result_Available_Time (1, WB_STAGE);
#else
  Result_Available_Time (0, 3 + EXTRA_LATENCY);
  Result_Available_Time (1, 3 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 2);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_CTL, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group23",
		TOP_asm_10_r_r_r,
		TOP_asm_11_r_r_r,
		TOP_asm_8_r_r_r,
		TOP_asm_9_r_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 4);
#endif
  Operand_Access_Time (0, 2);
  Operand_Access_Time (1, 2);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group24",
		TOP_asm_12_r_r_r,
		TOP_asm_13_r_r_r,
		TOP_asm_14_r_r_r,
		TOP_asm_15_r_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 4);
#endif
  Operand_Access_Time (0, 2);
  Operand_Access_Time (1, 2);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);


  Instruction_Group("group25",
		TOP_asm_24_i_r_r,
		TOP_asm_25_i_r_r,
		TOP_asm_26_i_r_r,
		TOP_asm_27_i_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 4);
#endif
  Operand_Access_Time (0, 2);
  Resource_Requirement(Resource_st220_ISSUE, 0);


  Instruction_Group("group26",
		TOP_asm_24_ii_r_r,
		TOP_asm_25_ii_r_r,
		TOP_asm_26_ii_r_r,
		TOP_asm_27_ii_r_r,
		TOP_asm_28_ii_r_r,
		TOP_asm_29_ii_r_r,
		TOP_asm_30_ii_r_r,
		TOP_asm_31_ii_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 4);
#endif
  Operand_Access_Time (0, 2);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group27",
		TOP_asm_28_i_r_r,
		TOP_asm_29_i_r_r,
		TOP_asm_30_i_r_r,
		TOP_asm_31_i_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 4);
#endif
  Operand_Access_Time (0, 2);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);


  Instruction_Group("group28",
		TOP_mulhhs_r_r_r,
		TOP_mulhhu_r_r_r,
		TOP_mulhh_r_r_r,
		TOP_mulhs_r_r_r,
		TOP_mulhu_r_r_r,
		TOP_mulh_r_r_r,
		TOP_mullhus_r_r_r,
		TOP_mullhu_r_r_r,
		TOP_mullh_r_r_r,
		TOP_mulllu_r_r_r,
		TOP_mulll_r_r_r,
		TOP_mullu_r_r_r,
		TOP_mull_r_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 3 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Operand_Access_Time (1, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);


  Instruction_Group("group29",
		TOP_mulhhs_ii_r_r,
		TOP_mulhhu_ii_r_r,
		TOP_mulhh_ii_r_r,
		TOP_mulhs_ii_r_r,
		TOP_mulhu_ii_r_r,
		TOP_mulh_ii_r_r,
		TOP_mullhus_ii_r_r,
		TOP_mullhu_ii_r_r,
		TOP_mullh_ii_r_r,
		TOP_mulllu_ii_r_r,
		TOP_mulll_ii_r_r,
		TOP_mullu_ii_r_r,
		TOP_mull_ii_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 3 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group30",
		TOP_mulhhs_i_r_r,
		TOP_mulhhu_i_r_r,
		TOP_mulhh_i_r_r,
		TOP_mulhs_i_r_r,
		TOP_mulhu_i_r_r,
		TOP_mulh_i_r_r,
		TOP_mullhus_i_r_r,
		TOP_mullhu_i_r_r,
		TOP_mullh_i_r_r,
		TOP_mulllu_i_r_r,
		TOP_mulll_i_r_r,
		TOP_mullu_i_r_r,
		TOP_mull_i_r_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 3 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (0, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ODD, 0);


  Instruction_Group("group31",
		TOP_ldbu_r_ii_r,
		TOP_ldbu_d_r_ii_r,
		TOP_ldb_r_ii_r,
		TOP_ldb_d_r_ii_r,
		TOP_ldhu_r_ii_r,
		TOP_ldhu_d_r_ii_r,
		TOP_ldh_r_ii_r,
		TOP_ldh_d_r_ii_r,
		TOP_ldw_r_ii_r,
		TOP_ldw_d_r_ii_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 3 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (1, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_MEM, 0);
  Resource_Requirement(Resource_st220_ODD, 0);
  Resource_Requirement(Resource_st220_EVEN, 0);


  Instruction_Group("group32",
		TOP_ldbu_r_i_r,
		TOP_ldbu_d_r_i_r,
		TOP_ldb_r_i_r,
		TOP_ldb_d_r_i_r,
		TOP_ldhu_r_i_r,
		TOP_ldhu_d_r_i_r,
		TOP_ldh_r_i_r,
		TOP_ldh_d_r_i_r,
		TOP_ldw_r_i_r,
		TOP_ldw_d_r_i_r,
		TOP_UNDEFINED);

#ifdef FORWARDING_DISABLED
  Result_Available_Time (0, WB_STAGE);
#else
  Result_Available_Time (0, 3 + EXTRA_LATENCY);
#endif
  Operand_Access_Time (1, 1);
  Resource_Requirement(Resource_st220_ISSUE, 0);
  Resource_Requirement(Resource_st220_MEM, 0);


  Machine_Done("rvex.c");

}
