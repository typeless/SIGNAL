process EXTMPS2 =
  ( ? event START, TICK;
    ! integer A; [3] integer P; [3] boolean Q; [2, 2] short R; [3] integer W; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := N
   | V := [N, N + 1, -N]
   | P := V * N
   | Q := V > 2
   | M := [[short(N), short(2)], [short(-N), short(32767)]]
   | R := M - short(N)
   | W := (V when N modulo 2 = 0) default (K when TICK)
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer N, ZN;
    [3] integer V;
    [2, 2] short M;
    constant [3] integer K = [7, 8, 9];
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
