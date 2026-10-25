process MIXED =
  ( ? event START, TICK;
    ! long A, B; integer C; boolean D, E, F, G, H, Q; short S; ulong U; long ZL; short ZS; boolean ZB; integer O; ubyte Y; uinteger V; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := uinteger(4294967295) + long(N)
   | B := short(-32768) * integer(N) - long(1)
   | C := short(N) * short(-32768) + integer(7)
   | D := ubyte(250) < short(0 - N)
   | E := uinteger(4294967295) < long(0 - N)
   | F := (N > 3) = (N < 6)
   | G := (N > 3) /= (N < 6)
   | H := (N modulo 2 = 0) and (N > 2) or not (N < 5)
   | Q := CL > color#green
   | CL := (color#green when ZC = #red) default (#blue when ZC = #green) default #red
   | ZC := CL $ init #red
   | CL ^= TICK
   | O := integer(CL)
   | S := ZS - short(1)
   | ZS := S $ init -32767
   | S ^= TICK
   | LL ^= TICK
   | BB ^= TICK
   | U := uinteger(N) * uinteger(4000000000) + ulong(N) * ulong(4000000000)
   | ZL := LL $ init -9223372036854775807
   | LL := ZL - 1
   | ZB := BB $ init true
   | BB := not ZB
   | Y := ubyte(N * 100) / ubyte(N)
   | V := uinteger(N * 1000000000) modulo uinteger(7)
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    type color = enum (red, green, blue);
    integer ZN, N;
    color CL, ZC;
    long LL;
    boolean BB;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
