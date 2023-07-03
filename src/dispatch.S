.align 2
.thumb_func
.global dispatch_entry

dispatch_entry:
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

  // 3.SPレジスタの値をctx_tblに格納
  ldr     r0, =ctx_tbl
  subs    r1, #1
  lsls    r1, r1, #2
  mov     r2, sp
  str     r2, [r0, r1]

disp_010:
  // 4.実行中タスクの変更
  ldr     r0, =next_task
  ldr     r1, [r0]
  ldr     r0, =cur_task
  str     r1, [r0]

  // 5.スタックの切り替え
  ldr     r0, =ctx_tbl
  subs    r1, #1
  lsls    r1, r1, #2
  ldr     r2, [r0, r1]
  mov     sp, r2

  // 6.スタック上のコンテキスト復元
  pop     {r0-r3}
  mov     r11, r3
  mov     r10, r2
  mov     r9, r1
  mov     r8, r0
  pop     {r4-r7}
  bx      lr
