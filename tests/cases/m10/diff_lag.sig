process LAGS =
  ( ? event START, TICK;
    ! integer Y0, P0, P1, P2, W0, W1, W2, E; short S0, S1; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | Y := N $ 2 init YI
   | A := [N, 10 * N, -N]
   | B := A $
   | D := A $ 2 init DI
   | W := A window 2 init WI
   | V := short(N) window 3
   | Y0 := Y
   | P0 := B[0]
   | P1 := D[2]
   | P2 := D[0]
   | W0 := W[0, 0]
   | W1 := W[1, 2]
   | W2 := W[0, 2]
   | S0 := V[0]
   | S1 := V[2]
   | E := (A $)[N modulo 3]
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer ZN, N, Y;
    [2, 3] integer W;
    [3] short V;
    [3] integer A, D;
    [3] integer B init [7, 8, 9];
    constant [2] integer YI = [-5, -6];
    constant [2, 3] integer DI = [[1, 2, 3], [4, 5, 6]];
    constant [1, 3] integer WI = [[-1, -2, -3]];
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
