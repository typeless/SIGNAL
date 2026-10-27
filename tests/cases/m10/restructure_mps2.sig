process RESTRUCTUREMPS2 =
  ( ? event START, TICK;
    ! integer A; [3] long X; [2, 2] short M; [3] ubyte Y; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := N
   | X[N modulo 3] := long(N) * long(-1000000000000)
   | M[1, N modulo 2] := short(-N)
   | Y := P : S
   | S := [ubyte(N), ubyte(N + 200)]
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer N, ZN;
    [2] ubyte S;
    constant [2] integer P = [2, 0];
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
