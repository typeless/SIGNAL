process DIVS =
  ( ? event START, TICK;
    ! short A, B, C; integer D, E, F; ubyte G; ushort H; ulong I, J, K, L; long M, P, Q, R; uinteger T; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := short(-32768) / short(0 - N)
   | B := short(-32768) modulo short(0 - N)
   | C := short(N - 4) modulo short(N - 4)
   | D := integer(-2147483648) / integer(0 - N)
   | E := integer(-2147483648) modulo integer(4 - N)
   | F := integer(N - 5) / integer(2)
   | G := ubyte(255) / ubyte(N - 1)
   | H := ushort(65535) modulo ushort(N * 100)
   | I := (ulong(0) - ulong(1)) / (ulong(1) shl ulong(63) + ulong(N))
   | J := (ulong(0) - ulong(1)) modulo (ulong(1) shl ulong(63) + ulong(N))
   | K := (ulong(1) shl ulong(63)) / ulong(N)
   | L := ulong(N) / (ulong(1) shl ulong(32))
   | M := long(-9223372036854775807) - long(1)
   | P := M / long(N - 2)
   | Q := M modulo long(N - 2)
   | R := long(N - 4) * long(1000000000) * long(1000000000) / long(7 - N)
   | T := uinteger(N) shr uinteger(N - 1)
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer ZN, N;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
