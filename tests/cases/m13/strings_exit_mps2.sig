process STRINGSEXITMPS2 =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   | LINE := if TALLY = 1 then "/dev/null" else if TALLY = 2 then "/" else if TALLY = 3 then "/dev/null" else "abc\0d"
   | PREVIOUS := LINE $ 1 init "none"
   | FIRST_LINE := LINE when TALLY = 1
   | FIRST := FIRST_LINE cell ^TALLY init ""
   | L :: BYTE := load{MEM, ubyte}(pointer(LINE))
   | W1 :: write("line ", LINE)
   | W2 :: write("previous ", PREVIOUS)
   | W3 :: write("first ", FIRST)
   | W4 :: write("same as previous ", LINE = PREVIOUS)
   | W5 :: write("before previous ", LINE < PREVIOUS)
   | W6 :: write("same as first ", LINE = FIRST)
   | W7 :: write("before first ", LINE < FIRST)
   | W8 :: write("first byte ", integer(BYTE))
   | W1 --> W2 --> W3 --> W4 --> W5 --> W6 --> W7 --> W8
   | L --> W8
   |)
  where
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    integer ZCOUNT;
    type MEM = external;
    string LINE, PREVIOUS, FIRST_LINE, FIRST;
    ubyte BYTE;
    label RELOAD, CURRENT, CONTROL, L, W1, W2, W3, W4, W5, W6, W7, W8;
  end;
