#*****************************************************************************
# illegal_tvec_cmd.S
#-----------------------------------------------------------------------------
#
# Test illegal tvec command trap.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64S
RVTEST_CODE_BEGIN

  setpcr status, SR_EI # enable interrupt

  la a3,handler
  mtpcr a3,evec # set exception handler

  mfpcr a3,status
  li a4,(1 << IRQ_COP)
  slli a4,a4,SR_IM_SHIFT
  or a3,a3,a4 # enable IM[COP]
  mtpcr a3,status

  .word 0xff00002b

  vsetcfg 32,0
  li a3,4
  vsetvl a3,a3

vtcode1:
  lw x2, 0(x1)
  stop

vtcode2:
  add x2,x2,x3
  stop

handler:
  vxcptkill

  li x28,2

  # check cause
  vxcptcause a3
  li a4,HWACHA_CAUSE_ILLEGAL_INSTRUCTION
  bne a3,a4,fail

  # check vec irq aux
  vxcptaux a3
  li a4, 0xff00002b
  bne a3,a4,fail

  # make sure vector unit has cleared out
  vsetcfg 32,0
  li a3,4
  vsetvl a3,a3

  la a3,src1
  la a4,src2
  vld vx2,a3
  vld vx3,a4
  lui a0,%hi(vtcode2)
  vf %lo(vtcode2)(a0)
  la a5,dest
  vsd vx2,a5
  fence

  ld a1,0(a5)
  li a2,5
  li x28,2
  bne a1,a2,fail
  ld a1,8(a5)
  li x28,3
  bne a1,a2,fail
  ld a1,16(a5)
  li x28,4
  bne a1,a2,fail
  ld a1,24(a5)
  li x28,5
  bne a1,a2,fail

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

src1:
  .dword 1
  .dword 2
  .dword 3
  .dword 4
src2:
  .dword 4
  .dword 3
  .dword 2
  .dword 1
dest:
  .dword 0xdeadbeefcafebabe
  .dword 0xdeadbeefcafebabe
  .dword 0xdeadbeefcafebabe
  .dword 0xdeadbeefcafebabe

RVTEST_DATA_END