process ARRDWMPS2 =
  ( ? event START, TICK;
    ! integer A; [2] integer W, X, Y; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := N
   | P := [N, N + 10]
   | Q := [-N, 0]
   | C := N modulo 2 = 1
   | D := N modulo 3 /= 0
   | W := (P when C) default (Q when D) default (K when TICK)
   | X := ((P when C) default Q) when D
   | Y := (P default Q) when C
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer N, ZN;
    boolean C, D;
    [2] integer P, Q;
    constant [2] integer K = [7, 8];
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
