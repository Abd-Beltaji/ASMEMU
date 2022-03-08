
;--- jfc.asm.
;--- Very simple file compare. Public Domain.
;--- Mixed-language application (uses CRT)

;--- Win32 binary:
;--- assemble: jwasm -coff jfc.asm crtexe.asm
;--- link:     link jfc.obj crtexe.obj msvcrt.lib

;--- Linux binary:
;--- assemble: jwasm -zcw -elf -D?MSC=0 -Fo jfc.o jfc.asm
;--- link:     gcc -o jfc jfc.o

    .386
    .MODEL FLAT, c
    option casemap:none

?USEDYN  equ 1  ;0=use static CRT, 1=use dynamic CRT
ifndef ?MSC
?MSC    equ 1  ;0=use gcc, 1=use ms CRT
endif

printf  proto c :ptr BYTE, :VARARG
fopen   proto c :ptr BYTE, :ptr BYTE
fclose  proto c :ptr
fseek   proto c :ptr, :DWORD, :DWORD
ftell   proto c :ptr
fread   proto c :ptr BYTE, :DWORD, :DWORD, :ptr
malloc  proto c :DWORD
free    proto c :ptr

SEEK_SET equ 0
SEEK_END equ 2

lf  equ 10

CStr macro text:VARARG
local xxx
    .const
xxx db text,0
    .code
    exitm <offset xxx>
    endm

;--- errno access
ife ?USEDYN
externdef c errno:dword   ; errno is global var
else
__errno macro
;--- if errno is to be defined as a function call
 if ?MSC
_errno proto c            ;ms crt
    call _errno
 else
__errno_location proto c  ;gcc
    call __errno_location
 endif
    mov eax,[eax]
    exitm <eax>
    endm
errno textequ <__errno()>
endif

    .CODE

main proc c argc:dword, argv:ptr

local file1:dword
local filesize1:dword
local buffer1:dword
local header1:dword
local file2:dword
local filesize2:dword
local buffer2:dword
local header2:dword
local cnt:dword
local fPE:byte
local fCoff:byte

    xor eax, eax
    mov fPE, 0
    mov fCoff, 0
    mov file1, eax
    mov file2, eax
;--- scan cmdline
    mov ebx,argv
    mov ecx, argc
    add ebx, 4
    dec ecx
    .while ( ecx )
        mov edx, [ebx]
        mov al,[edx]
        .if ( al == '-' || al == '/' )
            mov eax, [edx+1]
            movzx eax,ax
            or ax,2020h
            .if ( ax == "ep" )
                mov fPE, 1
            .elseif ( ax == "oc" )
                mov fCoff, 1
            .else
                invoke printf, CStr("unknown option",lf)
                mov eax,1
                ret
            .endif
        .elseif ( file1 == 0 )
            mov file1, edx
        .elseif ( file2 == 0 )
            mov file2, edx
        .else
            invoke printf, CStr("too many arguments",lf)
            mov eax,1
            ret
        .endif
        add ebx, 4
        dec ecx
    .endw

    .if ( file1 == 0 || file2 == 0 )
        invoke printf, CStr("jfc v1.2, Public Domain.",lf)
        invoke printf, CStr("jfc compares two binary files.",lf)
        invoke printf, CStr("usage: jfc [-co|-pe] file1 file2",lf)
        mov eax,1
        ret
    .endif

    mov cnt, 0
    mov ebx, file1
    invoke fopen, ebx, CStr("rb")
    .if ( !eax )
        invoke printf, CStr("open error file '%s' [%u]",lf), ebx, errno
        mov eax,1
        ret
    .endif
    mov ebx, eax
    invoke fseek, ebx, 0, SEEK_END
    invoke ftell, ebx
    mov filesize1, eax
    invoke fseek, ebx, 0, SEEK_SET
    mov eax, filesize1
    invoke malloc, eax
    .if ( eax == 0 ) 
        invoke printf, CStr("out of memory",lf)
        invoke fclose, ebx
        mov eax,1
        ret
    .endif
    mov buffer1, eax
    invoke fread, buffer1, 1, filesize1, ebx
    push eax
    invoke fclose, ebx
    pop eax
    .if ( eax != filesize1 )
        invoke printf, CStr("read error file '%s' [%u]",lf), file1, errno
        mov eax,1
        ret
    .endif

    mov ebx, file2
    invoke fopen, ebx, CStr("rb")
    .if ( !eax )
        invoke printf, CStr("open error file '%s' [%u]",lf), ebx, errno
        mov eax,1
        ret
    .endif
    mov ebx, eax
    invoke fseek, ebx, 0, SEEK_END
    invoke ftell, ebx
    mov filesize2, eax
    invoke fseek, ebx, 0, SEEK_SET
    mov eax, filesize2
    invoke malloc, eax
    .if ( eax == 0 ) 
        invoke printf, CStr("out of memory",lf)
        invoke fclose, ebx
        mov eax,1
        ret
    .endif
    mov buffer2, eax
    invoke fread, buffer2, 1, filesize2, ebx
    push eax
    invoke fclose, ebx
    pop eax
    .if ( eax != filesize2 )
        invoke printf, CStr("read error file '%s' [%u]",lf), file2, errno
        mov eax,1
        ret
    .endif

    mov esi, buffer1
    mov edi, buffer2

;--- when comparing PE binaries,
;--- 1. skip the MZ header
;--- 2. compare the PE header separately (without time stamp)
;--- 3. compare the rest

    .if ( fPE )
        mov ecx, file1
        mov eax, [esi+3Ch]
        add esi, eax
        cmp filesize1, eax
        jc faterr1
        cmp dword ptr [esi], "EP"
        jnz faterr1
        mov ecx, file2
        mov eax, [edi+3Ch]
        add edi, eax
        cmp filesize2, eax
        jc faterr1
        cmp dword ptr [edi], "EP"
        jnz faterr1

        mov eax, [esi+4+20+3Ch]         ;sizeof header
        mov header1, eax
        mov eax, [edi+4+20+3Ch]         ;sizeof header
        mov header2, eax

        movzx eax, word ptr [esi+4+2]   ;no of sections
        mov ecx, 40                     ;sizeof section header
        mul ecx
        add eax, 0E0h                   ;sizeof optional header
        add eax, 20+4                   ;sizeof file header + 4

        mov ecx, eax
        mov eax, [esi+8]                ;make timestamps equal
        mov [edi+8], eax
        call compare

        ;--- now prepare to compare the section contents
        mov ecx, file1
        mov esi, buffer1
        mov eax, header1
        add esi, eax
        sub filesize1, eax
        jc faterr1
        mov ecx, file2
        mov edi, buffer2
        mov eax, header2
        add edi, eax
        sub filesize2, eax
        jc faterr1
    .elseif ( fCoff )
        mov eax,[esi+4]     ;make timestamps equal
        mov [edi+4],eax
    .endif

    mov eax, filesize1
    .if ( eax != filesize2 ) 
        invoke printf, CStr("%s, %s: file sizes differ",lf), file1, file2
        mov eax,1
        ret
    .endif

    mov ecx, eax
    call compare

    invoke free, buffer1
    invoke free, buffer2

    mov eax, cnt
    and eax, eax
    setnz al
    movzx eax,al
    ret

compare:
    ;--- compare a block ( esi, edi, ecx )
    .while ( ecx )

        repz cmpsb

        setnz al
        movzx eax, al
        add cnt, eax

        .if ( eax )
            push ecx
            mov edx, esi
            dec edx
            sub edx, buffer1
            movzx eax,byte ptr [esi-1]
            movzx ecx,byte ptr [edi-1]
            invoke printf, CStr("%08Xh: %02X %02X (%s %s)",lf), edx, eax, ecx, file1, file2
            pop ecx
        .endif
    .endw
    retn

faterr1:
    invoke printf, CStr("invalid PE binary: %s",lf), ecx
    mov eax, 1
    ret
    align 4

main endp

    END
