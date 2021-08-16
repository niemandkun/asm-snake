text segment
        assume  cs:text, ds:text, es:nothing

Token struc
    @ptr dw ?
    @length dw ?
Token ends

size_of_token = 4

argc_ptr = 80h
argv_ptr = argc_ptr + 1


length_flag db '/LENGTH', 00h
length_flag_short db '/L', 00h

collision_flag db '/COLLISION', 00h
collision_flag_short db '/C', 00h

items_flag db '/ITEMS', 00h
items_flag_short db '/I', 00h

death_flag db 'DEATH', 00h
cut_flag db 'CUT', 00h
nothing_flag db 'NOTHING', 00h


parse_args proc c near uses bx cx dx

        mov     ax, ds
        mov     es, ax

        call    split_args_com

        mov     ax, cs
        mov     es, ax

        mov     cx, cs:[tokens_count]
        test    cx, cx
        jz      @@finish

        lea     bx, [tokens]

@@check_loop:
        push    bx
        call    process_parameter
        add     sp, 2

        sub     cx, ax
        jle     @@finish

        mov     dx, size_of_token
        mul     dx
        add     bx, ax
        jmp     @@check_loop

@@finish:
        ret

parse_args endp


flag_cmp proc
        ;   si -- parameter (in data segment)
        ;   di -- flag (in code segment)
        ;   dx -- short flag (in code segment)

        push    si

        push    dx
        call    str_compare
        add     sp, 2
        mov     dx, ax

        push    di
        call    str_compare
        add     sp, 4

        and     ax, dx

        ret

flag_cmp endp


single_flag_cmp macro flag
        push    si
        lea     di, [flag]
        push    di
        call    str_compare
        add     sp, 2+2
        test    ax, ax
endm


store_collision_type proc
        ; bx -- pointer to Token
        ; ret: ax = 1 if error, 0 otherwise

        xor     ax, ax
        mov     si, cs:[bx].@ptr
        test    si, si
        jz      @@error

@@death:
        single_flag_cmp death_flag
        jne     @@cut
        mov     cs:snake_collision_handler, offset collide_deadly_wall
        ret

@@cut:
        single_flag_cmp cut_flag
        jne     @@nothing
        mov     cs:snake_collision_handler, offset cut_snake
        ret

@@nothing:
        single_flag_cmp nothing_flag
        jne     @@error
        mov     cs:snake_collision_handler, 0
        ret

@@error:
        mov     ax, 1
        ret

store_collision_type endp


process_parameter proc c near uses bx cx si di
        arg @@token_ptr:word

        mov     bx, ss:[@@token_ptr]

        mov     si, cs:[bx].@ptr
        mov     cx, cs:[bx].@length

@@collision:
        lea     di, [collision_flag]
        lea     dx, [collision_flag_short]
        call    flag_cmp
        test    ax, ax
        jnz     @@length

        add     bx, size_of_token
        call    store_collision_type
        test    ax, ax
        jnz     @@invalid

        mov     ax, 2
        jmp     @@finish

@@length:
        lea     di, [length_flag]
        lea     dx, [length_flag_short]
        call    flag_cmp
        test    ax, ax
        jnz     @@items

        add     bx, size_of_token
        mov     bx, cs:[bx].@ptr
        push    bx
        call    parse_int
        pop     bx

        jc      @@invalid
        mov     cs:delta_length, ax

        mov     ax, 2
        jmp     @@finish

@@items:
        lea     di, [items_flag]
        lea     dx, [items_flag_short]
        call    flag_cmp
        test    ax, ax
        jnz     @@invalid

        add     bx, size_of_token
        mov     bx, cs:[bx].@ptr
        push    bx
        call    parse_int
        pop     bx

        jc      @@invalid
        mov     cs:items_count, ax

        mov     ax, 2
        jmp     @@finish

@@invalid:
        jmp     print_usage_and_exit

@@finish:
        ret

process_parameter endp


print_usage_and_exit proc near
        mov     ax, cs
        mov     ds, ax
        lea     dx, [help]
        mov     ah, 09h
        int     21h
        mov     ah, 4ch
        mov     al, 1
        int     21h
print_usage_and_exit endp


help db                                                                                0Ah
     db "Usage: SNAKE.EXE [/L LENGTH] [/I COUNT] [/C TYPE] [/?]",                      0Ah
     db                                                                                0Ah
     db "Play classic snake game.",                                                    0Ah
     db                                                                                0Ah
     db "Parameters:",                                                                 0Ah
     db "    /L, /LENGTH    - Initial snake length, default is 5",                     0Ah
     db "    /I, /ITEMS     - Number of bonus items to spawn, default is 10",          0Ah
     db "    /C, /COLLISION - Action to do, when snake collides with itself",          0Ah
     db "                     possible values: DEATH, CUT, NOTHING",                   0Ah
     db                                                                                0Ah
     db "    /?, /HELP      - Show this help message and exit",                        0Ah
     db                                                                                24h


split_args_com proc c near uses dx

        xor     dx, dx
        mov     dl, ds:[argc_ptr]
        push    dx

        mov     dx, argv_ptr
        push    dx

        call    split_args
        add     sp, 2 + 2

        ret

split_args_com endp


split_args proc c near uses ax dx
        arg @@argv_ptr:word, @@argc:word
        ; returns: count of tokens in ax, pointer to tokens in bx

        mov     dx, ss:[@@argc]

        test    dx, dx
        jz      @@finish

        push    dx

        mov     dx, ss:[@@argv_ptr]
        push    dx

        call    str_to_upper
        call    split_tokens
        add     sp, 2 + 2

        mov     cs:[tokens_count], ax
        mov     cx, size_of_token     ; cx - size of element
        mul     cx

        lea     dx, cs:[tokens]
        add     ax, dx
        mov     cs:[tokens_exclusive_end_ptr], ax

        call    unescape_and_terminate

@@finish:
        ret

split_args endp


unescape_and_terminate proc c near uses ax bx cx dx

        mov     cx, size_of_token             ; cx - size of element
        lea     ax, cs:[tokens]                ; ax - begin ptr
        mov     dx, cs:[tokens_exclusive_end_ptr] ; dx - end ptr

@@foreach_loop:
        push    ax
        call    unescape_token
        call    terminate_token
        pop     ax

        add     ax, cx
        cmp     ax, dx
        jb      @@foreach_loop

        ret

unescape_and_terminate endp


split_tokens proc c near uses bx cx dx si di es
        arg @@str_ptr:word, @@str_length:word
        ; fills array of tokens with data
        ; returns count of tokens

        mov     ax, cs
        mov     es, ax

        mov     si, ss:[@@str_ptr]
        mov     cx, ss:[@@str_length]
        lea     di, cs:[tokens]
        xor     dx, dx

@@read_token_loop:
        push    cx
        push    si
        call    read_spaces
        add     sp, 2 * 2

        sub     cx, ax
        add     si, ax

        test    cx, cx
        jle     @@finish

        mov     al, [si]        ; peek first character and choose what to do

@@single_quote:
        cmp     al, 27h
        je      @@quote

@@double_quote:
        cmp     al, 22h
        jne     @@space

@@quote:
        inc     si
        dec     cx
        push    ax
        jmp     @@read_token

@@space:
        mov     al, 20h
        push    ax

@@read_token:
        mov     ax, si
        stosw                   ; remember start of the token

        push    cx
        push    si
        call    read_token
        add     sp, 2 * 3

        stosw                   ; remember length of the token

        add     ax, 1
        add     si, ax
        sub     cx, ax

        inc     dx

        test    cx, cx
        jg      @@read_token_loop

@@finish:
        mov     ax, dx
        ret

split_tokens endp


read_spaces proc c near uses cx si
        arg @@str_ptr:word, @@str_length:word
        ; returns count of spaces

        mov     si, ss:[@@str_ptr]
        mov     cx, ss:[@@str_length]

@@read_loop:
        lodsb
        dec     cx
        jle     @@finish

        cmp     al, 20h     ; space
        je      @@read_loop

        cmp     al, 09h     ; tab
        je      @@read_loop

@@finish:
        mov     ax, ss:[@@str_ptr]   ; 0 1 2 3 4 5 6 7 8 9
        sub     si, ax              ; # # _ # # # # _ # #
        xchg    si, ax              ;       ^         ^
        dec     ax                  ;       ax        si
        ret                         ; thus, len = si - ax - 1

read_spaces endp


read_token proc c near uses bx cx dx si
        arg @@str_ptr:word, @@str_length:word, @@terminate_character:word
        ; returns length of read

        mov     dx, ss:[@@terminate_character]
        mov     bh, 5Ch     ; escape character ('\\')
        xor     bl, bl      ; escaped flag

        mov     si, ss:[@@str_ptr]
        mov     cx, ss:[@@str_length]

@@read_loop:
        lodsb
        cmp     al, dl              ; is character terminating?
        jne     @@non_terminating

        test    bl, bl              ; is character not escaped?
        jnz     @@non_terminating

        dec     si
        jmp     @@finish            ; if so, end reading

@@non_terminating:
        cmp     al, bh              ; is character escaping?
        jne     @@non_escaping

        test    bl, bl              ; is character not escaped?
        jnz     @@non_escaping

        mov     bl, 1               ; if so, set escaped = true
        jmp     @@loop_end

@@non_escaping:
        xor     bl, bl

@@loop_end:
        dec     cx
        jg      @@read_loop

@@finish:
        mov     ax, ss:[@@str_ptr]
        sub     si, ax
        xchg    si, ax
        ret

read_token endp


unescape_token proc c near uses bx dx
        arg @@token_ptr:word

        mov     bx, ss:[@@token_ptr]

        mov     dx, cs:[bx].@length
        push    dx

        mov     dx, cs:[bx].@ptr
        push    dx

        call    str_unescape

        add     sp, 2 * 2
        mov     word ptr cs:[bx].@length, ax
        ret

unescape_token endp


terminate_token proc c near uses ax bx cx
        arg @@token_ptr:word

        mov     bx, ss:[@@token_ptr]

        mov     ax, cs:[bx].@length
        mov     bx, cs:[bx].@ptr
        add     bx, ax

        mov     byte ptr ds:[bx], 00h

        ret

terminate_token endp


tokens_count dw ?
tokens Token 64 dup(?)
tokens_exclusive_end_ptr dw ?

text ends
