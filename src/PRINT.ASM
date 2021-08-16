print macro
        push    ax
        call    print_word
        add     sp, 2
endm

text segment
        assume  cs:text, ds:text, es:text

colon = 3Ah
new_line = 0Ah


print_segment_offset proc c near uses dx
        arg @@segment_address:word, @@offset:word

        mov     dx, [@@segment_address]
        push    dx
        call    print_word
        pop     dx

        mov     dx, colon
        push    dx
        call    put_char
        pop     dx

        mov     dx, [@@offset]
        push    dx
        call    print_word
        pop     dx

        mov     dx, new_line
        push    dx
        call    put_char
        pop     dx

        ret

print_segment_offset endp


put_char proc c near uses ax bx cx dx
        arg @@char_to_print:word

        mov     ax, [@@char_to_print]
        mov     ah, 0Ah
        mov     cx, 1
        xor     bx, bx
        int     10h

        mov     ah, 03h
        xor     bx, bx
        int     10h

        inc     dl

        mov     ah, 02h
        xor     bx, bx
        int     10h

        ret

put_char endp


print_new_line proc c near uses ax dx

        lea     dx, [@@new_line]
        mov     ah, 09h
        int     21h

        ret

@@new_line db 0Dh, 0Ah, 24h

print_new_line endp


print_byte proc c near uses ax dx
        arg @@byte_to_print:word

        mov     dx, 02h
        push    dx
        mov     dx, 10h
        push    dx
        mov     dx, [@@byte_to_print]
        push    dx
        call    print_number
        add     sp, 3 * 2
        mov     ah, 02h
        mov     dx, "h"
        int     21h
        ret

print_byte endp


print_word proc c near uses dx
        arg @@word_to_print:word

        mov     dx, 04h     ; add up to 4 leading zeros to adjust length
        push    dx

        mov     dx, 10h     ; radix
        push    dx

        mov     dx, [@@word_to_print]
        push    dx

        call    print_number

        add     sp, 3 * 2

        ;call    print_new_line

        ret

print_word endp


print_number proc c near uses ax bx cx dx
        arg @@number_to_print:word, @@radix:word, @@total_length:word

        mov     ax, [@@number_to_print]
        mov     bx, [@@radix]
        xor     cx, cx              ; counter for characters to print

@@division_loop:
        xor     dx, dx
        div     bx
        push    dx                  ; push remainder to stack
        inc     cx
        test    ax, ax
        jnz     @@division_loop

        mov     ah, 02h
        mov     dx, 30h             ; print leading zeros if need
        mov     bx, [@@total_length]

@@leading_zeros_loop:
        cmp     bx, cx
        jle     @@print_loop
        int     21h
        dec     bx
        jmp     @@leading_zeros_loop

@@print_loop:
        pop     dx
        cmp     dl, 0Ah
        jb      @@is_decimal
        add     dl, 07h             ; if hex number

@@is_decimal:
        add     dl, 30h
        int     21h
        dec     cx
        jnz     @@print_loop

        ret

print_number endp

text ends
