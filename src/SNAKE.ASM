        model   small
        locals

.stack

include com.asm
include string.asm
include print.asm
include args.asm
include ringbuf.asm
include inter.asm
include sound.asm
include zelda.asm
include model.asm
include graphics.asm
include random.asm
include bitmaps.asm

text segment
        assume  cs:text, ds:text, es:text

state_game:     ; offsets of handlers for each command
        dw      com_tick,       offset game_tick
        dw      com_up,         offset key_up
        dw      com_right,      offset key_right
        dw      com_left,       offset key_left
        dw      com_down,       offset key_down
        dw      com_sound,      offset on_sound
        dw      com_faster,     offset speed_up
        dw      com_slower,     offset speed_down
        dw      com_exit,       offset pause
        dw      com_gameover,   offset gameover
        dw      0FFFFh

state_main:
        dw      com_tick,       offset menu_tick
        dw      com_exit,       offset exit
        dw      com_start,      offset continue
        dw      com_help,       offset show_help
        dw      0FFFFh

state_pause:
        dw      com_tick,       offset menu_tick
        dw      com_exit,       offset gameover
        dw      com_start,      offset continue
        dw      0FFFFh

state_help:
        dw      com_tick,       offset menu_tick
        dw      com_exit,       offset show_menu
        dw      0FFFFh

state_gameover:
        dw      com_tick,       offset menu_tick
        dw      com_exit,       offset exit
        dw      0FFFFh

state   dw      offset state_main

start:
        call    parse_args

        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        call    setup_vector
        call    init_random
        call    init_model
        call    enable_graphics
        call    setup_sys_timer
        call    start_music

        call    show_menu

@@1:
        hlt
        call    ring_buffer_read
        jc      @@1
        mov     si, state
        xor     ah, ah
        mov     bx, ax
@@2:
        lodsw
        cmp     ax, 0FFFFh
        jz      @@1
        cmp     ax, bx
        jz      @@3
        add     si, 2
        jmp     @@2
@@3:
        lodsw
        call    ax
        jmp     @@1

;       handlers:

exit:
        call    stop_music
        call    reset_sys_timer
        call    restore_vector
        call    disable_graphics
        mov     ah, 4ch
        int     21h

logic_ticks dw 0
fixed_ticks dw 0

fixed_upd = 10h
logic_upd dw fixed_upd

pause_str       db "PAUSED", 24h
pause_help_str  db "RETURN - continue  ESC - exit", 24h

pause:
        push    ax
        push    bx
        push    si

        mov     state, offset state_pause
        call    clear_screen

        mov     ax, 136
        mov     bx, 80
        mov     si, offset pause_str
        call    draw_string

        mov     ax, 40
        mov     bx, 100
        mov     si, offset pause_help_str
        call    draw_string

        call    push_buffer

        pop     si
        pop     bx
        pop     ax
        ret

continue:
        call    stop_music
        mov     state, offset state_game
        call    clear_screen
        call    push_buffer
        mov     logic_ticks, 0
        mov     fixed_ticks, 0
        ret


game_over_str   db "GAME OVER",         24h
scores_str      db "Total Scores:",     24h
apples_str      db "Apples:",           24h
bad_apples_str  db "Bad Apples:",       24h

ricochets_str   db "Ricochets:",        24h
teleport_str    db "Teleportations:",   24h

length_str      db "Snake Length:",     24h
max_length_str  db "Maximal Length:",   24h

results_table:
        dw      offset scores_str,      offset scores
        dw      offset length_str,      offset snake_length
        dw      offset max_length_str,  offset max_length
        dw      offset apples_str,      offset apples_counter
        dw      offset bad_apples_str,  offset bad_apples_counter
        dw      offset ricochets_str,   offset rubber_wall_counter
        dw      offset teleport_str,    offset portal_wall_counter
        dw      0FFFFh

gameover:
        call    start_music
        mov     state, offset state_gameover
        call    clear_screen

        mov     ax, 124 ; column
        mov     bx, 20 ; row
        mov     si, offset game_over_str
        call    draw_string

        mov     di, offset results_table
        mov     bx, 40

@@cycle:
        mov     si, [di]
        cmp     si, 0FFFFh
        je      @@finish

        mov     ax, 20
        call    draw_string

        mov     si, [di+2]
        mov     ax, 276
        mov     cx, [si]
        call    draw_number
        add     di, 4
        add     bx, 20
        jmp     @@cycle

@@finish:
        call    push_buffer
        ret


menu_tick:
        call    update_sound
        ret

game_tick:
        push    ax
        push    bx
        push    cx
        call    update_sound
        cmp     logic_ticks, 0
        jge     @@fixed_update
        mov     ax, logic_upd
        mov     logic_ticks, ax
        call    update_model
        call    draw_scene
        mov     ax, 2
        mov     bx, 2
        mov     cx, scores
        call    draw_number
@@fixed_update:
        cmp     fixed_ticks, 0
        jge     @@finish
        mov     fixed_ticks, fixed_upd
        mov     ax, 6000h
        call    play_short_sound
@@finish:
        dec     logic_ticks
        dec     fixed_ticks
        pop     cx
        pop     bx
        pop     ax
        ret

on_sound:
        push    ax
        mov     ax, 2000h
        call    play_short_sound
        pop     ax
        ret

key_up:
        mov     velocity_x, 0
        mov     velocity_y, 1
        ret

key_down:
        mov     velocity_x, 0
        mov     velocity_y, -1
        ret

key_left:
        mov     velocity_x, -1
        mov     velocity_y, 0
        ret

key_right:
        mov     velocity_x, 1
        mov     velocity_y, 0
        ret

speed_up:
        dec     logic_upd
        cmp     logic_upd, 0
        jg      @@finish
        mov     logic_upd, 1
@@finish:
        ret

speed_down:
        inc     logic_upd
        cmp     logic_upd, 10h
        jle     @@finish
        mov     logic_upd, 10h
@@finish:
        ret

snake_title         db "SNAKE", 24h
start_game_str      db "Press RETURN Button", 24h
help_message_str    db "h - help", 24h

show_menu:
        mov     state, offset state_main

        call    clear_screen

        mov     ax, 140
        mov     bx, 60
        mov     si, offset snake_title
        call    draw_string

        mov     ax, 88
        mov     bx, 100
        mov     si, offset start_game_str
        call    draw_string

        mov     ax, 240
        mov     bx, 180
        mov     si, offset help_message_str
        call    draw_string

        call    push_buffer

        ret

items_title         db "ITEMS:", 24h

apple_desc          db "- apple, increase length", 24h
bad_apple_desc      db "- bad apple, decrease length", 24h
poison_desc         db "- explosives, death", 24h
rubber_wall_desc    db "- rubber wall, ricochet", 24h
portal_wall_desc    db "- portal wall, teleportation", 24h
deadly_wall_desc    db "- spiked wall, death", 24h

controls_title      db "CONTROLS:", 24h
arrows_keys         db "ARROWS - control snake", 24h
speed_keys          db "PLUS/MINUS - adjust speed", 24h
pause_key           db "ESCAPE - pause", 24h

back_to_menu        db "ESC - back to menu", 24h

items_table:
        dw offset apple_bitmap, offset apple_desc
        dw offset bad_apple_bitmap, offset bad_apple_desc
        dw offset poison_bitmap, offset poison_desc
        dw offset rubber_wall_bitmap, rubber_wall_desc
        dw offset portal_wall_bitmap, portal_wall_desc
        dw offset deadly_wall_bitmap, deadly_wall_desc
        dw 0FFFFh

show_help:
        mov     state, offset state_help

        call    clear_screen

        mov     ax, 20
        mov     bx, 10
        mov     si, offset items_title
        call    draw_string

        mov     di, offset items_table
        add     bx, 14

@@items_draw_cycle:
        mov     si, [di]
        cmp     si, 0FFFFh
        je      @@finish

        mov     ax, 20
        call    draw_bitmap

        mov     si, [di+2]
        mov     ax, 40
        call    draw_string
        add     di, 4
        add     bx, 14
        jmp     @@items_draw_cycle

@@finish:

        mov     ax, 20
        mov     bx, 120
        mov     si, offset controls_title
        call    draw_string

        mov     ax, 20
        add     bx, 14
        mov     si, offset arrows_keys
        call    draw_string

        mov     ax, 20
        add     bx, 14
        mov     si, offset speed_keys
        call    draw_string

        mov     ax, 20
        add     bx, 14
        mov     si, offset pause_key
        call    draw_string

        mov     ax, 150
        mov     bx, 180
        mov     si, offset back_to_menu
        call    draw_string

        call    push_buffer
        ret

text ends

end start
