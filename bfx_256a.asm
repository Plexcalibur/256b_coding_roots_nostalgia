[org 0x100]

        mov ax, 13h         ; Modus 13h laden
        int 10h             ; BIOS Video Services aufrufen

       ; PALLETTE
        xor cl, cl
        pallette_loop:
        mov dx, 3C8h      ; Indexregister for color palette (0x3C8)
        mov al, cl        
        out dx, al        ; init color for redefine
        inc dx 
        out dx, al        ; red = counter
        shr al, 1         
        out dx, al        ; green = red >> 1
        shr al, 1         
        out dx, al        ; blue = green >> 1
        loop pallette_loop

    game_loop:

        mov ax, si
        call sqCos
        mov dx, ax
        mov ax, si
        call sqSin
        mov cx, ax

        sub cx, 64
        sub dx, 96
        shl cx, 1
        shl dx, 1

        mov di, 0xA000
        test si, 512 + 256
        jnz doRoto

    fireScreen:
        pusha
        mov es, di
        mov di, 65535 - 321
      next:
        xor bx, bx
        mov al, byte [es:di]
        mov bl, byte [es:di+320]
        add ax, bx
        shr ax, 1
        mov [es:di], al

        dec di
        jnz next

        popa
        jmp WaitForNextFrame


      doRoto:
        ; calculate start position
        add [xPos], cx
        sub [yPos], dx
        mov ax, [xPos]
        mov bx, [yPos]

        loop_y:
        mov es, di
        mov di, 320

        push ax
        push bx

        loop_x:
        add ax, cx
        add bx, dx

        ;PaintPixel
        pusha
        xor ah, bh
        test ah, 4
        jz noPaint
        cmp ah, 64
        jl doPaint
        mov ax, di
        sub ax, si
        call sqSin
        mov bh, al
        mov ax, es
        add ax, si
        shr ax, 2
        call sqSin
        add al, bh
        add ax, di
        call sqSin
        mov ah, al
        shr ah, 2
        add ah, 64
      doPaint:
        mov [es:di], ah
      noPaint:
        popa

      afterPaintPixel:
        dec di
        jns loop_x       ; Do next pixel in row

        pop bx
        pop ax

        add bx, cx
        sub ax, dx

        mov di, es
        add di, 20
        cmp di, 44960
        jl loop_y

	; Wait until Retrace
    WaitForNextFrame:
        inc si
        and si, 1023

        mov dx, 0x03da
    WaitNotVSync:
        in al, dx
        and al, 0x08
        jnz WaitNotVSync
    WaitVSync:
        in al, dx
        and al, 0x08
        jz WaitVSync
    
    wait_for_esc:
        in al, 60h       ; read scan code from keyboard
        dec al           ; == 1 ?
        jnz game_loop    

    found_esc:
	      ; exit
	      ret

    sqCos:
        add al, 64
    sqSin:
        push bx
        ;    int i = cnt & 255;
        xor ah, ah
        ;    boolean big = (i & 128) != 0;
        mov bl, al
        ;    i &= 127;
        and al, 127
        ;    i -= 64;
        sub ax, 64
        ;    int val = 128 - (i * i) / 32;
        imul ax, ax
        shr ax, 5
        sub ax, 128
        neg ax
        ;    if (big) {
        ;        val = -val;
        ;    }
        test bl, 128
        jz sqSin_no_neg
        neg ax
      sqSin_no_neg:
        add ax, 128
        pop bx
        or ah, ah
        jz sqSin_ret
        dec ax
      sqSin_ret:
        ret

    xPos db  0x07, 0x30;
    yPos db  0x02, 0x05;
    weWereHere db 66, 70, 88  ; "BFX"
