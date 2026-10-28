process NESTEDMPS2 =
  ( ? event START, TICK;
    ! integer S, C; [3, 2] integer T; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | I := 2 .. 4
   | J := indices(2)
   | K := indices(2)
   | A := [N, 10 * N]
   | TN := [[N, N], [N, N], [N, N]]
   | iterate I of
       iterate J of
         (| S := S[?] * 7 + I * 3 + J + N
          | T[I - 2, J] := T[?][I - 2, J] + (A $)[J] + I
          |)
       end
     with (| S := 0 | T := TN |)
     end
   | R := 0 .. (N modulo 3)
   | iterate R of
       iterate K of
         C := C[?] + R * 2 + K + 1
       end
     with C := 0
     end
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer ZN, N;
    [3] integer I, R;
    [2] integer J, K, A;
    [3, 2] integer TN;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
