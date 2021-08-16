text segment
    assume cs:text

apple_bitmap:
    dw 10, 10

    db 5Bh,5Bh,5Bh,5Bh,13h,5Bh,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,13h,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,13h,13h,13h,5Bh,13h,13h,5Bh,5Bh
    db 5Bh,13h,13h,5Bh,13h,13h,13h,13h,13h,5Bh
    db 5Bh,13h,5Bh,13h,13h,13h,13h,13h,13h,5Bh
    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,5Bh
    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,5Bh
    db 5Bh,5Bh,13h,13h,13h,13h,13h,13h,5Bh,5Bh
    db 5Bh,5Bh,5Bh,13h,13h,13h,13h,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh

bad_apple_bitmap:
    dw 10, 10

    db 5Bh,5Bh,5Bh,5Bh,13h,5Bh,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,13h,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,13h,13h,13h,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,13h,13h,5Bh,5Bh,13h,5Bh,5Bh,5Bh
    db 5Bh,5Bh,13h,5Bh,5Bh,5Bh,13h,5Bh,5Bh,5Bh
    db 5Bh,5Bh,13h,5Bh,13h,5Bh,13h,5Bh,5Bh,5Bh
    db 5Bh,5Bh,13h,5Bh,5Bh,5Bh,13h,5Bh,5Bh,5Bh
    db 5Bh,5Bh,13h,13h,5Bh,5Bh,13h,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,13h,13h,13h,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh

snake_bitmap:
    dw 10, 10

    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,5Bh
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,5Bh

snake_head_bitmap:
    dw 10, 10

    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,5Bh
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,5Bh

poison_bitmap:
    dw 10, 10

    db 5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,13h,13h,5Bh,13h,13h,5Bh,5Bh
    db 5Bh,5Bh,13h,13h,13h,13h,5Bh,5Bh,13h,5Bh
    db 5Bh,13h,5Bh,13h,5Bh,13h,13h,5Bh,13h,5Bh
    db 5Bh,13h,13h,5Bh,13h,5Bh,13h,5Bh,13h,5Bh
    db 5Bh,13h,5Bh,13h,5Bh,13h,13h,5Bh,13h,5Bh
    db 5Bh,13h,13h,5Bh,13h,5Bh,13h,5Bh,13h,5Bh
    db 5Bh,13h,5Bh,13h,5Bh,13h,13h,5Bh,13h,5Bh
    db 5Bh,5Bh,13h,13h,13h,13h,5Bh,5Bh,13h,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh

rubber_wall_bitmap:
    dw 10, 10

    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,5Bh
    db 13h,5Bh,5Bh,13h,13h,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,13h,5Bh,5Bh,5Bh,5Bh,13h,13h,5Bh,13h
    db 13h,5Bh,13h,5Bh,5Bh,13h,5Bh,5Bh,13h,13h
    db 13h,5Bh,5Bh,13h,13h,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,13h,5Bh,5Bh,5Bh,5Bh,13h,13h,5Bh,13h
    db 13h,5Bh,13h,5Bh,5Bh,13h,5Bh,5Bh,13h,13h
    db 13h,5Bh,5Bh,13h,13h,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,13h,5Bh,5Bh,5Bh,5Bh,13h,13h,5Bh,13h
    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,5Bh

deadly_wall_bitmap:
    dw 10, 10

    db 5Bh,13h,5Bh,13h,5Bh,13h,5Bh,13h,5Bh,5Bh
    db 5Bh,13h,13h,13h,13h,13h,13h,13h,13h,13h
    db 13h,13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h,5Bh
    db 5Bh,13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h,13h
    db 13h,13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h,5Bh
    db 5Bh,13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h,13h
    db 13h,13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h,5Bh
    db 5Bh,13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h,13h
    db 13h,13h,13h,13h,13h,13h,13h,13h,13h,5Bh
    db 5Bh,5Bh,13h,5Bh,13h,5Bh,13h,5Bh,13h,5Bh

portal_wall_bitmap:
    dw 10, 10

    db 5Bh,13h,5Bh,13h,5Bh,13h,5Bh,13h,5Bh,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,13h
    db 13h,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh,5Bh
    db 5Bh,5Bh,13h,5Bh,13h,5Bh,13h,5Bh,13h,5Bh


text ends
