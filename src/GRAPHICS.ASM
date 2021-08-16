segment buffer_segment

double_buffer   db  64000 dup(?)

buffer_segment ends


text segment
        assume  cs:text, ds:text, es:text

bios_rom_segment = 0040h

bios_video_mode = 0049h
bios_video_page = 0062h

old_page db ?
old_mode db ?


field_color = 5Bh

head_color = 0Ch
snake_color = 04h

apple_color = 02h
poison_color = 05h
bad_apple_color = 06h

deadly_wall_color = 00h
rubber_wall_color = 39h
portal_wall_color = 09h

draw_head:
        push    si
        mov     si, offset snake_head_bitmap
        call    draw_bitmap
        pop     si
        mov     ax, offset draw_snake
        ret

draw_apple:
        push    si
        mov     si, offset apple_bitmap
        call    draw_bitmap
        pop     si
        mov     ax, offset draw_apple
        ret

draw_bad_apple:
        push    si
        mov     si, offset bad_apple_bitmap
        call    draw_bitmap
        pop     si
        mov     ax, offset draw_bad_apple
        ret

draw_poison:
        push    si
        mov     si, offset poison_bitmap
        call    draw_bitmap
        pop     si
        mov     ax, offset draw_poison
        ret

draw_snake:
        push    si
        mov     si, offset snake_bitmap
        call    draw_bitmap
        pop     si
        mov     ax, offset draw_snake
        ret

draw_empty:
        mov     cl, field_color
        call    fill_tile
        xor     ax, ax
        ret

draw_rubber_wall:
        push    si
        mov     si, offset rubber_wall_bitmap
        call    draw_bitmap
        pop     si
        mov     ax, offset draw_rubber_wall
        ret

draw_deadly_wall:
        push    si
        mov     si, offset deadly_wall_bitmap
        call    draw_bitmap
        pop     si
        mov     ax, offset draw_deadly_wall
        ret

draw_portal_wall:
        push    si
        mov     si, offset portal_wall_bitmap
        call    draw_bitmap
        pop     si
        mov     ax, offset draw_portal_wall
        ret


enable_graphics   proc
        push    es
        push    ax

        mov     ax, bios_rom_segment
        mov     es, ax

        mov     al, es:[bios_video_mode]
        mov     old_mode, al
        mov     al, es:[bios_video_page]
        mov     old_page, al

        mov     ax, 13h
        int     10h

        call    clear_screen
        call    push_buffer

        pop     ax
        pop     es
        ret
enable_graphics   endp


disable_graphics   proc
        xor     ax, ax
        mov     al, old_mode
        int     10h
        mov     ah, 05h
        mov     al, old_page
        int     10h
        ret
disable_graphics   endp


draw_scene      proc
        call    draw_tiles
        call    push_buffer
        ret
draw_scene      endp


tile_width = 10
tile_height = 10

screen_width = 320
screen_height = 200


draw_tiles      proc c near uses ax bx cx si ds es
        push    ds
        push    es

        mov     ax, tiles
        mov     ds, ax

        mov     ax, buffer_segment
        mov     es, ax

        xor     si, si
        xor     ax, ax
        xor     bx, bx
@@cycle:
        call    draw_tile
        add     si, size_of_tile
        cmp     si, offset tiles_end_ex
        jge     @@finish

        add     ax, tile_width
        cmp     ax, screen_width
        jne     @@cycle

        xor     ax, ax
        add     bx, tile_height
        jmp     @@cycle

@@finish:
        pop     es
        pop     ds
        ret
draw_tiles      endp


draw_tile       proc c near uses ax cx
        ; args:
        ;       es - buffer segment
        ;       ax - most left column
        ;       bx - most upper row
        ;       ds:si - pointer to Tile
        ; ret:
        ;       none
        mov     cx, [si].@draw_proc
        test    cx, cx
        jz      @@finish
        call    cx
        mov     [si].@draw_proc, ax
@@finish:
        ret
draw_tile       endp


fill_tile       proc c near uses ax bx dx si di
        ; args:
        ;       ax - column
        ;       bx - row
        ;       cl - color
        ; ret:
        ;       none

        ; compare colors
        ; if colors match, nothing to do
        ;push    cx
        ;call    get_pixel
        ;mov     dx, cx
        ;pop     cx
        ;cmp     cl, dl
        ;je      @@finish

        mov     di, tile_height
        dec     di
@@cycle_y:
        mov     si, tile_width
        dec     si
@@cycle_x:
        add     ax, si
        add     bx, di
        call    set_pixel
        sub     bx, di
        sub     ax, si

        dec     si
        jge     @@cycle_x
        dec     di
        jge     @@cycle_y

@@finish:
        ret
fill_tile       endp


draw_bitmap     proc c near uses ax bx cx dx si di ds
        ; args:
        ;       ax - column
        ;       bx - row
        ;       si - bitmap ptr
        ; ret:
        ;       none

        call    get_pixel_addr
        mov     di, bx
        ; DI = offset of top-left pixel

        mov     ax, cs
        mov     ds, ax

        mov     ax, buffer_segment
        mov     es, ax

        lodsw   ; width
        mov     cx, ax
        lodsw   ; height
        mul     cx
        mov     dx, ax
        ; DX = total size of bitmap
        ; CX = width of bitmap
@@1:
        mov     ax, cx
@@2:
        movsb

        dec     dx
        jz      @@finish

        dec     ax
        jnz     @@2

        add     di, 320
        sub     di, cx
        jmp     @@1

@@finish:
        ret
draw_bitmap     endp


draw_string     proc c near uses ax cx si
        ; args:
        ;       AX = column
        ;       BX = row
        ;       DS:SI = string ptr
        ; ret:
        ;       none
@@1:
        mov     ch, ds:[si]
        cmp     ch, '$'
        je      @@2
        call    draw_char
        add     ax, 8
        inc     si
        jmp     @@1
@@2:
        ret
draw_string     endp


draw_number     proc c near uses ax bx cx dx si di
        ; args:
        ;       AX = column
        ;       BX = row
        ;       CX = number to write
        ; ret:
        ;       none
        mov     si, ax
        mov     di, bx

        mov     ax, cx
        mov     bx, 10  ; radix
        xor     cx, cx  ; counter for characters to print

@@division_loop:
        xor     dx, dx
        div     bx
        push    dx      ; push remainder to stack
        inc     cx
        test    ax, ax
        jnz     @@division_loop

        mov     ax, si  ; row
        mov     bx, di  ; column
        mov     dx, cx  ; count of characters

@@print_loop:
        pop     cx
        add     cl, 30h
        xchg    cl, ch
        call    draw_char
        add     ax, 8
        dec     dx
        jnz     @@print_loop

        ret
draw_number endp


draw_char       proc c near uses ax bx cx si di ds es
        ; args:
        ;       AX = column
        ;       BX = row
        ;       CH = character to write
        ; ret:
        ;       none
        call    get_pixel_addr
        mov     di, bx

        mov     ax, 0f000h
        mov     ds, ax

        mov     ax, buffer_segment
        mov     es, ax

        mov     cl, ch
        xor     ch, ch
        mov     ax, cx
        mov     cl, 3
        shl     ax, cl

        mov     si, 0fa6eh
        add     si, ax

        mov     cx, 8
@@2:
        lodsb
        mov     ah, 80h
@@1:
        test    al, ah
        jz      @@bg

        mov     bl, 13h
        jmp     @@continue

@@bg:
        mov     bl, 5Bh

@@continue:
        mov     es:[di], bl

        inc     di
        shr     ah, 1

        test    ah, ah
        jnz     @@1

        add     di, 320 - 8
        dec     cx
        jnz     @@2

        ret
draw_char       endp


clear_screen    proc
        push    es

        mov     ax, buffer_segment
        mov     es, ax
        lea     di, [double_buffer]
        xor     di, di
        mov     ah, field_color
        mov     al, field_color
        mov     cx, 32000
        rep     stosw

        pop     es
        ret
clear_screen    endp


set_pixel       proc c uses ax bx
        ; args:
        ;       ax - column
        ;       bx - row
        ;       cl - color
        ; ret:
        ;       none
        call    get_pixel_addr
        mov     byte ptr es:[bx], cl

        ret
set_pixel       endp


get_pixel       proc c uses ax bx
        ; args:
        ;       ax - column
        ;       bx - row
        ; ret:
        ;       cl - color
        call    get_pixel_addr
        mov     cl, byte ptr es:[bx]

        ret
get_pixel       endp


get_pixel_addr  proc
        ; args:
        ;       ax - column
        ;       bx - row
        ; ret:
        ;       bx - address of pixel in double buffer

        push    dx
        xchg    ax, bx
        mov     dx, 320
        mul     dx
        add     bx, ax
        add     bx, offset double_buffer

        pop     dx
        ret
get_pixel_addr  endp


push_buffer     proc
        push    es
        push    ds
        mov     ax, 0a000h
        mov     es, ax

        mov     ax, buffer_segment
        mov     ds, ax

        mov     si, offset double_buffer
        xor     di, di
        mov     cx, 32000
        rep     movsw

        pop     ds
        pop     es
        ret
push_buffer     endp

text ends
