tiles segment

size_of_tile = 6

Tile struc
    @snake dw 0
    @draw_proc dw 0
    @collision_proc dw 0
Tile ends

Tile 640 dup(?)
tiles_end_ex = $

snake   dw  640 dup(?)
snake_end_ex = $

field_width = 32
field_height = 20

tiles ends


text segment
        assume  cs:text

velocity_x dw 1
velocity_y dw 0

delta_length dw 5
snake_length dw 0

snake_start_x = 15
snake_start_y = 15

snake_head_x dw snake_start_x
snake_head_y dw snake_start_y

snake_head_ptr dw offset snake
snake_tail_ptr dw offset snake

head_tile_ptr dw 0

items_count dw 10

scores dw 0
apples_counter dw 0
bad_apples_counter dw 0

rubber_wall_counter dw 0
portal_wall_counter dw 0

max_length dw 0

apple_scores = 10
bad_apple_scores = 5

snake_collision_handler dw offset collide_deadly_wall

items:
    dw offset draw_apple, offset collide_apple
    dw offset draw_apple, offset collide_apple
    dw offset draw_apple, offset collide_apple
    dw offset draw_bad_apple, offset collide_bad_apple
    dw offset draw_poison, offset collide_poison
    dw offset draw_poison, offset collide_poison

walls:
    dw offset draw_deadly_wall, offset collide_deadly_wall
    dw offset draw_rubber_wall, offset collide_rubber_wall
    dw offset draw_portal_wall, offset collide_portal_wall

map:
    dw      5, 4,       5, 15,      2
    dw      26, 4,      26, 15,     2
    dw      11, 0,      20, 0,      1
    dw      11, 19,     20, 19,     1
    dw      9, 4,       10, 4,      0
    dw      21, 4,      22, 4,      0
    dw      9, 15,      10, 15,     0
    dw      21, 15,     22, 15,     0
    dw      0ffffh

portals:
    dw      5, 26
    dw      26, 5
    dw      0ffffh

init_model      proc c near uses ax bx cx dx es
        mov     ax, tiles
        mov     es, ax

        ; set pointer to tile with snake head in snake array
        mov     ax, snake_head_x
        mov     bx, snake_head_y

        call    get_tile_ptr
        mov     es:[bx].@draw_proc, offset draw_head

        mov     head_tile_ptr, bx
        mov     dx, bx
        ; pointer in DX now

        mov     bx, snake_head_ptr
        mov     es:[bx], dx

        call    build_walls

        ; spawn initial items
        mov     cx, items_count

        test    cx, cx
        jz      @@finish

@@cycle:
        mov     ax, 6
        call    spawn_item
        dec     cx
        jnz     @@cycle

@@finish:
        ret
init_model      endp


spawn_item      proc c near uses ax bx cx si
        ; args:
        ;       AX = count of items to select
        ; ret:
        ;       none
        ;
        push    ax
@@cycle:
        mov     ax, field_height
        call    random_get
        mov     bx, ax          ; row in BX
        mov     ax, field_width
        call    random_get      ; column in AX

        call    get_tile_ptr    ; ptr to tile in BX

        cmp     bx, head_tile_ptr
        je      @@cycle

        cmp     es:[bx].@collision_proc, 0
        jne     @@cycle

        cmp     es:[bx].@snake, 0
        jne     @@cycle

        pop     ax
        call    random_get

        shl     ax, 1
        shl     ax, 1
        add     ax, offset items

        mov     si, ax

        lodsw
        mov     es:[bx].@draw_proc, ax

        lodsw
        mov     es:[bx].@collision_proc, ax

        ret
spawn_item      endp


build_walls     proc
        mov     di, offset map
@@cycle:
        mov     ax, [di]
        cmp     ax, 0ffffh
        je      @@finish
        mov     bx, [di+2]
        mov     cx, [di+4]
        mov     dx, [di+6]
        mov     si, [di+8]
        shl     si, 1
        shl     si, 1
        add     si, offset walls
        call    build_wall
        add     di, 10
        jmp     @@cycle
@@finish:
        ret
build_walls     endp


build_wall      proc
        ; args:
        ;       (AX, BX), (CX, DX) = coordinates
        ;       SI = ptr to callbacks
        push    di
        mov     di, ax
@@y:
        mov     ax, di
@@x:
        push    ax
        push    bx

        call    get_tile_ptr
        mov     ax, [si]
        mov     es:[bx].@draw_proc, ax
        mov     ax, [si+2]
        mov     es:[bx].@collision_proc, ax

        pop     bx
        pop     ax

        inc     ax
        cmp     ax, cx
        jle     @@x

        inc     bx
        cmp     bx, dx
        jle     @@y

        pop     di
        ret
build_wall      endp


update_model    proc c near uses ax bx es
        mov     ax, tiles
        mov     es, ax

        call    move_head
        call    move_tail
        call    check_collision
        ret
update_model    endp


move_head       proc c near uses ax bx
        mov     ax, snake_head_x
        mov     bx, snake_head_y

        add     ax, velocity_x
        add     bx, velocity_y

        call    torus_cycle

        mov     snake_head_x, ax
        mov     snake_head_y, bx

        call    get_tile_ptr
        ; got ptr to new snake head in BX
        mov     head_tile_ptr, bx

        ; update head tile draw func and snake counter
        mov     es:[bx].@draw_proc, offset draw_head

        mov     dx, bx
        ; ptr to new head is in DX now

        ; install collision handler for old head tile
        mov     ax, snake_collision_handler
        mov     bx, snake_head_ptr
        mov     bx, es:[bx]
        mov     es:[bx].@collision_proc, ax
        inc     es:[bx].@snake

        ; create pointer to new head
        mov     bx, snake_head_ptr
        add     bx, 2
        cmp     bx, offset snake_end_ex
        jne     @@write_head_ptr

        mov     bx, offset snake

@@write_head_ptr:
        ; write pointer to new head into the new cell
        mov     es:[bx], dx
        mov     snake_head_ptr, bx

        ret
move_head       endp


move_tail       proc c near uses ax bx
        mov     ax, delta_length
        test    ax, ax
        jz      @@do_move_tail

        dec     ax
        mov     delta_length, ax
        mov     ax, snake_length
        inc     ax
        cmp     ax, max_length
        jle     @@1
        mov     max_length, ax
@@1:
        mov     snake_length, ax
        jmp     @@finish

@@do_move_tail:
        mov     bx, snake_tail_ptr
        mov     bx, es:[bx]
        ; pointer to tile in BX

        dec     es:[bx].@snake
        jg      @@is_not_empty

        mov     es:[bx].@collision_proc, 0

        cmp     bx, head_tile_ptr
        je      @@is_not_empty

        mov     es:[bx].@draw_proc, offset draw_empty

@@is_not_empty:
        mov     bx, snake_tail_ptr
        add     bx, 2
        cmp     bx, offset snake_end_ex
        jne     @@write_tail_ptr

        mov     bx, offset snake

@@write_tail_ptr:
        mov     snake_tail_ptr, bx

@@finish:
        ret
move_tail       endp


rotate_snake    proc c near uses ax bx si di
        mov     bx, snake_tail_ptr
        mov     bx, es:[bx]
        dec     es:[bx].@snake

        mov     bx, snake_head_ptr
        mov     bx, es:[bx]
        mov     es:[bx].@draw_proc, offset draw_snake
        inc     es:[bx].@snake

        mov     si, snake_head_ptr
        mov     di, snake_tail_ptr

        mov     ax, es:[di]
        call    get_coords
        mov     snake_head_x, ax
        mov     snake_head_y, bx

        neg     velocity_x
        neg     velocity_y

@@cycle:
        mov     ax, es:[si]
        mov     bx, es:[di]

        mov     es:[si], bx
        mov     es:[di], ax

        add     di, 2
        sub     si, 2

        cmp     si, di
        jg      @@cycle

        ret
rotate_snake    endp


check_collision proc near
        push    bx
        push    ax

        mov     bx, snake_head_ptr
        mov     bx, es:[bx]
        ; got pointer to head tile in bx

        mov     ax, es:[bx].@collision_proc
        test    ax, ax
        jz      @@finish
        call    ax
        mov     ax, com_sound
        call    ring_buffer_write

@@finish:
        pop     ax
        pop     bx
        ret
check_collision endp


collide_apple   proc near
        inc     delta_length
        inc     apples_counter
        add     scores, apple_scores
        mov     ax, 4
        call    spawn_item
        mov     es:[bx].@collision_proc, 0
        ret
collide_apple   endp


collide_bad_apple proc near
        inc     bad_apples_counter
        add     scores, bad_apple_scores

        call    move_tail
        dec     snake_length

        mov     ax, snake_head_ptr
        cmp     ax, snake_tail_ptr
        jne     @@finish

        mov     ax, com_gameover
        call    ring_buffer_write

@@finish:
        mov     ax, 4
        call    spawn_item
        mov     es:[bx].@collision_proc, 0
        ret
collide_bad_apple endp


collide_poison  proc near
        mov     ax, com_gameover
        call    ring_buffer_write
        mov     es:[bx].@collision_proc, 0
        ret
collide_poison  endp


collide_deadly_wall proc near
        mov     ax, com_gameover
        call    ring_buffer_write
        mov     es:[bx].@draw_proc, offset draw_deadly_wall
        ret
collide_deadly_wall endp


collide_rubber_wall proc near
        inc     rubber_wall_counter
        call    rotate_snake
        call    move_head
        call    move_tail
        mov     es:[bx].@draw_proc, offset draw_rubber_wall
        mov     es:[bx].@collision_proc, offset collide_rubber_wall
        mov     es:[bx].@snake, 0
        ret
collide_rubber_wall endp


collide_portal_wall proc c near uses ax bx cx si
        inc     portal_wall_counter

        mov     es:[bx].@draw_proc, offset draw_portal_wall
        mov     es:[bx].@collision_proc, offset collide_portal_wall
        mov     es:[bx].@snake, 0

        mov     ax, bx
        call    get_coords

        mov     cx, ax  ; column

        mov     si, offset portals
@@find_target:
        lodsw
        cmp     ax, 0ffffh
        je      @@finish
        cmp     ax, cx
        je      @@teleport
        add     si, 2
        jmp     @@find_target

@@teleport:
        lodsw
        ; AX = column
        ; BX = row

        cmp     velocity_y, 0
        je      @@2

        ; hack to deal with vertical teleportation
        cmp     bx, 15
        jne     @@1
        mov     bx, 4
        jmp     @@2
@@1:
        cmp     bx, 4
        jne     @@2
        mov     bx, 15
@@2:
        add     ax, velocity_x
        add     bx, velocity_y

        mov     snake_head_x, ax
        mov     snake_head_y, bx

        call    get_tile_ptr

        mov     si, snake_head_ptr
        mov     es:[si], bx

        mov     es:[bx].@draw_proc, offset draw_head

@@finish:
        ret
collide_portal_wall endp


cut_snake       proc c near uses bx dx si
        mov     dx, bx
        ; pointer to collision tile in DX

        ;cmp     es:[bx].@snake, 0
        ;je      @@return

        mov     bx, snake_tail_ptr

@@cycle:
        dec     snake_length
        mov     si, es:[bx]
        ; pointer to tile in SI

        dec     es:[si].@snake
        jg      @@1

        mov     es:[si].@collision_proc, 0

        cmp     si, head_tile_ptr
        je      @@1

        mov     es:[si].@draw_proc, offset draw_empty

@@1:
        add     bx, 2
        cmp     si, dx
        je      @@finish
        jmp     @@cycle

@@finish:
        mov     snake_tail_ptr, bx
@@return:
        ret
cut_snake       endp


get_tile_ptr    proc near
        ; args:
        ;       ax - column
        ;       bx - row
        ; ret:
        ;       bx - ptr to tile struct
        push    cx
        push    dx

        xchg    ax, bx
        xor     dx, dx

        mov     cx, field_width
        mul     cx

        add     ax, bx

        mov     cx, size_of_tile
        mul     cx

        xchg    ax, bx

        pop     dx
        pop     cx
        ret
get_tile_ptr    endp


get_coords      proc near
        ; args:
        ;       ax - ptr to tile struct
        ; ret:
        ;       ax - column
        ;       bx - row
        push    cx
        push    dx

        xor     dx, dx
        mov     cx, size_of_tile
        div     cx

        xor     dx, dx
        mov     cx, field_width
        div     cx

        mov     bx, ax
        mov     ax, dx

        pop     dx
        pop     cx
        ret
get_coords      endp


torus_cycle     proc
        ; args:
        ;       AX - column
        ;       BX - row
        ; ret:
        ;       coordinates on torus:
        ;       0 <= AX < field_width
        ;       0 <= BX < field_height
@@ax_under:
        cmp     ax, 0
        jge     @@ax_over
        add     ax, field_width
        jmp     @@ax_under

@@ax_over:
        cmp     ax, field_width
        jl      @@bx_under
        sub     ax, field_width
        jmp     @@ax_over

@@bx_under:
        cmp     bx, 0
        jge     @@bx_over
        add     bx, field_height
        jmp     @@bx_under

@@bx_over:
        cmp     bx, field_height
        jl      @@finish
        sub     bx, field_height
        jmp     @@bx_over

@@finish:
        ret
torus_cycle     endp


clamp           proc
        ; args:
        ;       ax, bx, cx - numbers
        ; ret:
        ;       bx, if ax <= bx <= cx
        ;       ax, if bx < ax
        ;       cx, if cx < bx
        call    max
        mov     bx, cx
        call    min
        ret
clamp           endp


min             proc
        ; args:
        ;       ax - first number
        ;       bx - second number
        ; ret:
        ;       ax - minimum of two numbers
        cmp     ax, bx
        jl      @@finish
        xchg    ax, bx
@@finish:
        ret
min             endp


max             proc
        ; args:
        ;       ax - first number
        ;       bx - second number
        ; ret:
        ;       ax - maximum of two numbers
        cmp     ax, bx
        jg      @@finish
        xchg    ax, bx
@@finish:
        ret
max             endp

text ends
