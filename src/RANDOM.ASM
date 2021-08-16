text segment

init_random proc c near uses ax cx dx
@@cycle:
        mov     ah, 2Ch     ; get current time in dx
        int     21h
        test    dx, dx
        ; repeat while dx != 0
        jz      @@cycle
        mov     random_seed, dx
        ret
init_random endp


random_get proc c near uses bx dx
        ; args:
        ;       AX = upper exclusive bound
        ; ret:
        ;       random number in AX
        mov     bx, ax
        call    random_next
        xor     dx, dx
        div     bx
        mov     ax, dx
        ret
random_get endp


random_next proc c near uses bx cx dx
        ; args:
        ;       none
        ; ret:
        ;       random number in ax
        mov     ax, random_seed

        ; seed = (seed * LARGE_PRIME_1) % LARGE_PRIME_2
        xor     dx, dx
        mov     bx, 27361
        mul     bx

        xor     dx, dx
        mov     bx, 27751
        div     bx

        xchg    ax, dx
        mov     random_seed, ax

        ret
random_next endp

random_seed dw ?

text ends
