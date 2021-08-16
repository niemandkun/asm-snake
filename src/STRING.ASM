text segment
        assume  cs:text, ds:text, es:text

upper_case_z = "Z"
upper_case_a = "A"
upper_case_f = "F"
lower_case_a = "a"
lower_case_f = "f"
lower_case_z = "z"
space = " "
backslash = "\"

to_lower_delta = lower_case_a - upper_case_a
to_upper_delta = -to_lower_delta

digits_offset = "0"
lower_case_offset = lower_case_a - 10
upper_case_offset = upper_case_a - 10


parse_int proc c near uses bx cx si
        arg @@str_ptr:word
        ; returns: ax = integer, cf = 0 on succes
        ; ax = ?, cf = 1 on error

        mov     si, ss:[@@str_ptr]

        xor     bx, bx      ; accumulator

@@cycle:
        xor     ax, ax

        lodsb
        test    al, al
        jz      @@finish

        call    parse_digit
        jc      @@finish

        xchg    ax, bx
        mov     cl, 0Ah
        mul     cl
        xchg    ax, bx

        add     bx, ax
        jmp     @@cycle

@@finish:
        mov     ax, bx
        ret

parse_int endp


parse_digit:
        ;   args: al -- hexadecimal digit character
        ;   returns: ax = number if no errors, cf = 1 otherwise

        clc

        cmp     al, "0"
        jb      @@error
        cmp     al, "9"
        ja      @@error
        sub     al, digits_offset
        ret

@@error:
        stc
        ret


str_to_lower proc c near uses ax cx si di
        arg @@str_ptr:word, @@str_length:word

        mov     cx, ss:[@@str_length]
        mov     si, ss:[@@str_ptr]
        mov     di, ss:[@@str_ptr]

@@start_loop:
        lodsb

        cmp     al, upper_case_z
        ja      @@is_not_letter
        cmp     al, upper_case_a
        jb      @@is_not_letter

        add     al, to_lower_delta
        stosb
        jmp     @@end_loop

@@is_not_letter:
        inc     di

@@end_loop:
        dec     cx
        jg      @@start_loop

        ret

str_to_lower endp


str_to_upper proc c near uses ax cx si di
        arg @@str_ptr:word, @@str_length:word

        mov     cx, ss:[@@str_length]
        mov     si, ss:[@@str_ptr]
        mov     di, ss:[@@str_ptr]

@@start_loop:
        lodsb

        cmp     al, lower_case_z
        ja      @@is_not_letter
        cmp     al, lower_case_a
        jb      @@is_not_letter

        add     al, to_upper_delta
        stosb
        jmp     @@end_loop

@@is_not_letter:
        inc     di

@@end_loop:
        dec     cx
        jg      @@start_loop

        ret

str_to_upper endp


str_unescape proc c near uses si di bx cx
        arg @@str_ptr:word, @@str_length:word

        mov     si, ss:[@@str_ptr]
        mov     di, si
        mov     cx, ss:[@@str_length]
        xor     bx, bx      ; unescaped string length
        xor     dl, dl      ; escaped flag

@@unescape_loop:
        lodsb
        cmp     al, backslash
        jne     @@is_not_escape

        test    dl, dl
        jnz     @@is_not_escape

        mov     dl, 1
        jmp     @@continue


@@is_not_escape:
        xor     dl, dl
        inc     bx
        stosb

@@continue:
        dec     cx
        jg      @@unescape_loop

        mov     ax, bx
        ret

str_unescape endp


str_compare proc c near uses si di cx
        arg @@first:word, @@second:word
        ; compare two zero terminated strings
        ; returns: ax = 0 if strings are equal, 1 otherwise

        mov     si, ss:[@@second]
        mov     di, ss:[@@first]

        push    si
        call    str_length
        add     sp, 2
        mov     cx, ax

        push    ds
        mov     ax, es
        mov     ds, ax

        push    di
        call    str_length
        add     sp, 2

        pop     ds

        cmp     cx, ax
        jne     @@compare_fail

@@compare_loop:
        cmpsb
        jne     @@compare_fail
        dec     cx
        jnz     @@compare_loop
        xor     ax, ax
        jmp     @@return

@@compare_fail:
        mov     ax, 1

@@return:
        ret

str_compare endp


str_length proc c near uses si cx
        arg @@string:word
        ; calculate a length of the zero terminated string
        ; returns: ax = length of the given string

        mov     si, ss:[@@string]
        xor     cx, cx

@@length_loop:
        lodsw
        test    al, al
        jz      @@finish
        inc     cx
        test    ah, ah
        jz      @@finish
        inc     cx
        jmp     @@length_loop

@@finish:
        mov     ax, cx
        ret

str_length endp


str_print proc c near uses ax bx dx
        ; print zero terminated string
        arg @@string:word

        mov     dx, ss:[@@string]

        push    dx
        call    str_length
        add     sp, 2

        mov     bx, dx
        add     bx, ax

        mov     byte ptr [bx], 24h
        mov     ah, 09h
        int     21h

        mov     byte ptr [bx], 00h

        ret

str_print endp

text ends
