process NEXTCOPY =
  ( ? event START, TICK;
    ! long K0, K1, K2, K3; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | BR := BASE[R]
   | BR ^= TICK
   | M := indices(2)
   | M ^= TICK
   | iterate M of KK := BR next (M + N) : long(N) * 1000 end
   | K0 := KK[0]
   | K1 := KK[1]
   | K2 := KK[2]
   | K3 := KK[3]
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    constant [4] long BASE = [5, 7, 9, 11];
    constant [4] integer R = [3, 2, 1, 0];
    integer ZN, N;
    [4] long BR, KK;
    [2] integer M;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
