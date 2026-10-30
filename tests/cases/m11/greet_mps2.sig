process GREETMPS2 =
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
   | HELLO :: writeString(GREETING when START)
   | LETTER :: write("tick ", char(TALLY + 64))
   | MARK :: write("mark ", if TALLY modulo 2 = 0 then '\xE9' else '~')
   | PHASE := if TALLY > 2 then "late " else "early "
   | NAME :: write(PHASE, PLACE when TICK)
   | HELLO --> LETTER --> MARK --> NAME
   |)
  where
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    constant string GREETING = "hello from mps2";
    constant string PLACE = "mps2";
    integer ZCOUNT;
    string PHASE;
    label RELOAD, CURRENT, CONTROL, HELLO, LETTER, MARK, NAME;
  end;
