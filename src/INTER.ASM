text segment
        assume  cs:text, ds:text, es:text

old9:
old9offset dw ?
old9segment dw ?

old8:
old8offset dw ?
old8segment dw ?

key_commands:
        ;
        ; convert scancode into command code
        ;
        db      01h,    com_exit
        db      50h,    com_up
        db      4Dh,    com_right
        db      4Bh,    com_left
        db      48h,    com_down
        db      0Ch,    com_slower
        db      0Dh,    com_faster
        db      1Ch,    com_start
        db      23h,   com_help
        db      0FFh,   0FFh    ; EOT


int9 proc near
        push    ax

        in      al, 60h
        call    get_command
        cmp     al, 0FFh
        je      @@end_of_interrupt
        call    ring_buffer_write

@@end_of_interrupt:

        in      al, 61h
        or      al, 80h
        out     61h, al
        and     al, 7Fh
        out     61h, al

        mov     al, 20h
        out     20h, al

        pop     ax
        iret
int9 endp


int8 proc near
        push    ax
        mov     ax, com_tick
        call    ring_buffer_write
        pop     ax

        jmp     dword ptr cs:[old8]
int8 endp


get_command proc near
        push    si
        push    bx
        push    ds

        mov     bx, ax

        mov     ax, cs
        mov     ds, ax

        lea     si, [key_commands]

@@search_cycle:
        lodsb
        cmp     al, 0FFh
        je      @@finish

        cmp     al, bl
        je      @@finish

        inc     si
        jmp     @@search_cycle

@@finish:
        lodsb
        pop     ds
        pop     bx
        pop     si

        ret
get_command endp


setup_vector proc near
        push    ax
        push    di
        push    si

        lea     si, [int9]
        lea     di, [old9]
        mov     al, 9
        call    _setup_vector

        lea     si, [int8]
        lea     di, [old8]
        mov     al, 8
        call    _setup_vector

        pop     si
        pop     di
        pop     ax
        ret
setup_vector endp


_setup_vector proc near
        ;
        ;   args: al - vector number
        ;         di - where to store old vector
        ;         si - ptr to handler
        ;

        push    es
        push    dx
        push    bx
        push    ax

        mov     ah, 35h
        int     21h

        mov     cs:[di], bx
        mov     cs:[di+2], es

        mov     dx, si
        mov     ah, 25h
        int     21h

        pop     ax
        pop     bx
        pop     dx
        pop     es
        ret
_setup_vector endp


restore_vector proc near
        push    ds
        push    ax
        push    bx

        mov     dx, word ptr cs:[old9offset]
        mov     bx, word ptr cs:[old9segment]
        mov     ds, bx
        mov     ax, 2509h
        int     21h

        mov     dx, word ptr cs:[old8offset]
        mov     bx, word ptr cs:[old8segment]
        mov     ds, bx
        mov     ax, 2508h
        int     21h

        pop     bx
        pop     ax
        pop     ds
        ret
restore_vector endp

text ends
