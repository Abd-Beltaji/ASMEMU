
 1. About

    This is an enhanced clone of the MS-DOS/PC DOS DEBUG command which has
    many features not available in the original DEBUG. For details see below.


 2. Files Overview

    The files in this distribution are:

    debug.com     the executable binary.
    debugx.com    a DPMI aware version of Debug.
    readme.txt    this file.
    history.txt   list of changes.
    debug.txt     a MS-Debug tutorial originally written by Michael Webster,
                  extended to describe all additional features of DEBUG/X.

    The following files are also part of the distribution, but
    they're only needed if debug.com or debugx.com is to be rebuilt:

    debug.asm     Assembler source code for both debug.com and debugx.com.
                  Assemble with JWasm or MASM (see make.bat).
    debugtbl.inc  include file for debug.asm, contains tables for Debug's
                  internal assembler and disassembler commands.
    fptostr.inc   include file for debug.asm, contains the routine to
                  convert a floating-point number to ASCII.
    instr.*       input data for mktables.
    mktables.c    C program to compile the internal instruction set
                  tables into source file debugtbl.inc.
    make.bat      batch file to build debug.com and debugx.com.
    makec.bat     batch file to build mktables.exe.


 3. Added/Missing Features

  a. This debugger extends MS-DOS Debug in the following ways:

   - The assembler and disassembler support all instructions including FPU
     instructions for Intel chips through the Pentium Pro (P6), except for the
     MMX instructions (as for DEBUGX, MMX is partially supported since v1.18).
     The assembler and disassembler inform you if any instruction is
     inappropriate for the current processor.

   - The current processor (for the purposes of assembler and disassembler
     warnings, above) can be declared to be something else via the following
     commands:

        m [x] set current processor.
              0 = 8086/8088, 1 = 80186/80188, 2 = 80286, 3 = 80386,
              4 = 80486, 5 = Pentium, 6 = Pentium Pro (or later).
              no argument = print current CPU/FPU types.
        mc [2|N] set math coprocessor.
             2 = math coprocessor is a 287 (only valid if current
                 processor is 80386).
             N = math coprocessor is absent
             no argument = math coprocessor is present

   - 'r register [value]' accepts 32-bit register names (for CPU 80386+).

   - You can enter 'r cx 1234' instead of having to put the '1234' on a
     separate line.

   - register names can be used anywhere where a number is expected as
     input. That is, things like "u cs:ip" do work.

   - 'rn' displays FPU registers.

   - 'rx' switches between 16-bit and 32-bit register display (for CPU 80386+).

   - 'd', 'p', 't' and 'u' are automatically repeated if a blank line is
     entered.

   - 'db', 'dw' and 'dd' displays bytes, words or dwords. The last display
     type selected is used for subsequent 'd' commands.

   - 'dm' displays the DOS memory control block (MCB) chain and the
     current PSP.

   - 'h' can handle dword values.

   - Besides 'i' and 'o' exist the variations 'iw', 'id', 'ow' and 'od'
     to read/write a WORD or DWORD value from/to a port [DWORD values
     require a 80386+ CPU].

   - 'pr' skips out of the current subroutine by proceeding past the next
     RET, RETF or IRET which is not nested without stopping.

   - 'tm 0|1' sets trace command mode, 0 = process INTs (default),
     1 = single-step INTs (the MS-DOS Debug compatible mode).

   - 'xr' allows reallocation of an EMS handle and 'xa' allows allocation of an
     "empty" EMS handle (with zero pages) - but only if an EMM v4.0 is present.

   - if DOS has set its InDOS flag, DEBUG will avoid using Int 21h
     internally, which allows single-stepping through DOS code.

   - When doing 'debug < file', debug will not hang if it reaches an end of
     file before encountering a 'q' command.

   - This debugger saves and restores the program's Control-C and critical
     error interrupts, providing for better isolation between the debugger
     and the program being debugged.

  b. A DPMI aware version of the debugger, DEBUGX, is available, with the
     following additional features:

   - besides real-mode applications it can debug both 16-bit and 32-bit
     DPMI clients.
     [To debug DPMI clients a DPMI host has to be installed. Tested with
      cwsdpmi, hdpmi, WinXP NTVDM, 32rtm. In DosEmu and Windows 95/98/ME
      DOS boxes it is required to single-step through the initial switch
      to protected-mode, else DEBUGX will lose control of the debuggee.]

   - 'di': display interrupt vector(s)

   - 'dl': display LDT descriptor(s) (in protected-mode only)

   - 'dx': display extended memory (read via Int 15h, ah=87h). Requires a
     80386 CPU. 'dx' is automatically repeated if a blank line is entered.

   - 'rm' displays MMX registers.

   - 'rn' displays FPU registers in "readable" format.

  c. Optionally, one may build special-purpose versions of DEBUG.
     Run "make extra" to build them; you'll need the JWasm assembler
     for a successful run. The additional versions are:

   - DebugxD.COM: a version which doesn't hook Int 01 and Int 03. This
     allows to debug this version with a "normal" version of DEBUG.

   - DebugxE.COM: a version which hooks interrupts 06, 0Ch and 0Dh in
     real-mode. This is for - rare - cases when such exceptions may
     occur in real-mode applications.

   - DebugxF.COM: a version which hooks interrupt 31h in protected-mode
     and then rejects any attempt to modify exception vectors 01, 03,
     0Dh and 0Eh. This allows to debug DOS-extended applications that
     modify these vectors.

   - Debug.SYS: a version that is in DOS device driver format. This
     variant can be used to debug other device drivers. There are a few
     peculiarities: commands N and Q are rejected, commands L and W can't be
     used to load or write files and interrupt 06 (invalid opcode exception)
     is hooked.

  d. The following features of MS-DOS Debug are not implemented:

   - Loading of .HEX files.


 4. How to rebuild the DEBUG.COM/DEBUGX.COM Binaries

    MAKE.BAT is intended for rebuilding the debugger binaries. The
    recommended tool for this is the JWasm assembler. Alternatively,
    MASM can be used, but then a 16-bit OMF linker will be needed.


 5. Copyright

    This program is copyrighted, but feel free to use it as you wish.
    For full copyright conditions, see the file debug.asm.

    Paul Vojta
    vojta@math.berkeley.edu
