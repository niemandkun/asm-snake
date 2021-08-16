text segment
        assume  cs:text, ds:text, es:text

buffer_length = 20

buffer  db      buffer_length dup (0)

buffer_end = $

head    dw      offset buffer
tail    dw      offset buffer

ring_buffer_write proc near
        push    bx
        mov     bx, cs:head
        mov     byte ptr cs:[bx], al
        mov     ax, bx
        inc     word ptr cs:head
        cmp     word ptr cs:head, offset buffer_end
        jne     @@no_head_resumption
        mov     cs:head, offset buffer
@@no_head_resumption:
        mov     bx, cs:head
        cmp     bx, cs:tail
        jne     @@buffer_is_not_full
        mov     cs:head, ax
@@buffer_is_not_full:
        pop     bx
        ret
ring_buffer_write endp

ring_buffer_read proc near
        push    bx
        mov     bx, cs:tail
        cmp     bx, cs:head
        jne     @@buffer_is_not_empty
        pop     bx
        stc
        ret
@@buffer_is_not_empty:
        mov     al, byte ptr cs:[bx]
        inc     word ptr cs:tail
        cmp     word ptr cs:tail, offset buffer_end
        jne     @@no_tail_resumption
        mov     word ptr cs:tail, offset buffer
@@no_tail_resumption:
        pop     bx
        clc
        ret
ring_buffer_read endp

text ends
