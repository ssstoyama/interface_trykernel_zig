.align 2
.thumb_func
.global dispatch_entry

dispatch_entry:
  movs    r0, #1
  msr     primask, r0
  ldr     r1, =disp_running
  str     r0, [r1]

  // 1.実行中タスクのコンテキストをスタックに退避
  push    {r4-r7}
  mov     r0, r8
  mov     r1, r9
  mov     r2, r10
  mov     r3, r11
  push    {r0-r3}

  // 2.実行中タスク確認
  ldr     r0, =cur_task
  ldr     r1, [r0]
  cmp     r1, #0
  // cur_task_id=0ならdisp_010へ
  beq     disp_010

  // 3.実行コンテキストへのポインタを実行中のタスクのTCBに格納
  mov     r2, sp
  str     r2, [r1]

disp_010:
  // 4.実行中タスクの変更
  ldr     r1, =sche_task
  ldr     r2, [r1]
  cmp     r2, #0
  bne     disp_030
  
  // 5.スタックの切り替え
  str     r2, [r0]
disp_020:
  movs    r3, #0
  msr     primask, r3
  movs    r3, #1
  msr     primask, r3

  ldr     r2, [r1]
  cmp     r2, #0
  beq     disp_020

  // 6.実行するタスク切り替え
disp_030:
  str     r2, [r0]
  ldr     r0, [r2]
  mov     sp, r0

  // 7.スタック上のコンテキスト復元
  pop     {r0-r3}
  mov     r11, r3
  mov     r10, r2
  mov     r9, r1
  mov     r8, r0
  pop     {r4-r7}

  ldr     r0, =disp_running
  movs    r1, #0
  str     r1, [r0]
  msr     primask, r1

  bx      lr
