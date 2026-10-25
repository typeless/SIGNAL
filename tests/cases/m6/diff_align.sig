process ALIGN =
  ( ? event START, TICK;
    ! long A; ulong B; integer C; short D; long E; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := LONGS[N modulo 2]
   | B := ULONGS[N modulo 3]
   | C := INTS[N modulo 2]
   | D := SHORTS[N modulo 2]
   | E := ZE + LONGS[0]
   | ZE := E $ init 1234567890123
   | E ^= TICK
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    constant [3] ubyte BYTES = "abc";
    constant [2] long LONGS = [1234567890123456, -9876543210987];
    constant [1] ubyte ONE = [ubyte(7)];
    constant [3] ulong ULONGS = [ulong(1), ulong(-1), ulong(4294967296)];
    constant [5] ubyte FIVE = "hello";
    constant [2] integer INTS = [integer(-2147483648), 7];
    constant [1] ubyte ONE2 = [ubyte(9)];
    constant [2] short SHORTS = [short(-7), short(5)];
    integer ZN, N;
    long ZE;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
