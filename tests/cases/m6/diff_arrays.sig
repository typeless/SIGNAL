process ARRAYS =
  ( ? event START, TICK;
    ! integer A, B, C, D, E, F, G0, G1, G2, G3, H0, H1, H2, W0, W1, W2, K0, K1, K2; short S0, S1; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := TAB[N - 5]
   | B := TAB[long(N) - 5]
   | C := TAB[ulong(N) - ulong(5)]
   | D := TAB[short(N) - short(5)]
   | E := TAB[ubyte(N) + ubyte(250)]
   | F := TAB[integer(N) * 1000000000]
   | G := TAB[ORDER]
   | G0 := G[0]
   | G1 := G[1]
   | G2 := G[2]
   | G3 := G[3]
   | I := indices(1)
   | iterate I of Z := Z[?][R] with Z := SRC end
   | H0 := Z[0]
   | H1 := Z[1]
   | H2 := Z[2]
   | BR := BASE[R]
   | J := indices(3)
   | iterate J of SS := SS[?] next J : SS[?][J] + N with SS := BR end
   | W0 := SS[0]
   | W1 := SS[1]
   | W2 := SS[2]
   | M := indices(3)
   | iterate M of KK := KK[?] next (M + N - 1) : KK[?][M] * 2 with KK := BR end
   | K0 := KK[0]
   | K1 := KK[1]
   | K2 := KK[2]
   | SH := SHORTS[ORDER]
   | S0 := SH[2]
   | S1 := SH[3]
   | G ^= TICK
   | SH ^= TICK
   | I ^= TICK
   | J ^= TICK
   | M ^= TICK
   | BR ^= TICK
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    constant [4] integer TAB = [10, 11, 12, 13];
    constant [4] integer ORDER = [3, -1, 9, 2];
    constant [3] integer R = [2, 0, 1];
    constant [3] integer SRC = [100, 200, 300];
    constant [3] integer BASE = [5, 7, 9];
    constant [4] short SHORTS = [short(-32768), short(32767), short(-1), short(7)];
    integer ZN, N;
    [4] integer G;
    [4] short SH;
    [1] integer I;
    [3] integer J, M, Z, SS, KK, BR;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
