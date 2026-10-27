process ARRAYOUTPUTMPS2 =
  ( ? event START, TICK;
    ! integer A; [3] long T; [2] ubyte C; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := N
   | T := V next (N modulo 3) : long(N) * long(-1000000000000)
   | C := G[N modulo 3]
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer N, ZN;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
    constant [3] long V = [long(1), long(2), long(3)];
    constant [3] [2] ubyte G = [[ubyte(7), ubyte(8)], [ubyte(9), ubyte(10)], [ubyte(11), ubyte(12)]];
  end;
