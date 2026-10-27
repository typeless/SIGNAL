process SUBARRAYMPS2 =
  ( ? event START, TICK;
    ! integer A, B; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | R := G[N modulo 4]
   | A := integer(R[0])
   | B := integer(R[1])
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer N, ZN;
    [2] ubyte R;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
    constant [2, 3, 4] integer M = [[[1, 2, 3, 4], [11, 12, 13, 14], [21, 22, 23, 24]],
                                    [[101, 102, 103, 104], [111, 112, 113, 114], [121, 122, 123, 124]]];
    constant [3] [2] ubyte G = [[ubyte(7), ubyte(8)], [ubyte(9), ubyte(10)], [ubyte(11), ubyte(12)]];
  end;
