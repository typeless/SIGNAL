process CONCATMPS2 =
  ( ? event START, TICK;
    ! integer A; [3] short Z; [2, 2] ubyte W; boolean E, F; [3] long G; [2] long D; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := N
   | Z := S |+ T
   | S := [short(N), short(N * -100)]
   | T := [short(-N)]
   | W := Q |+ Q
   | E := S == U
   | U := [short(N), short(N * -100)]
   | F := Q == R
   | R := [[ubyte(N), ubyte(N + 1)]]
   | G := K[I1, I2]
   | I1 := [N modulo 3, 2, 5]
   | I2 := [1, N modulo 3, 0]
   | D := V[1 .. 2]
   | V := [long(N), long(-N), long(7)]
   | Q := [[ubyte(N), ubyte(N + 250)]]
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer N, ZN;
    [2] short S;
    [1] short T;
    [1, 2] ubyte Q, R;
    [2] short U;
    [3] integer I1, I2;
    [3] long V;
    constant [3, 3] long K = [[1, 2, 3], [4, 5, 6], [7, 8, 9]];
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
