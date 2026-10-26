process P =
  ( ! uinteger U1; boolean B1; long L1; short S1; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | U1 := U when N > 0
   | B1 := B when N > 0
   | L1 := L when N > 0
   | S1 := S when N > 0
   |)
  where
    integer ZN, N;
    constant uinteger U = uinteger(1) shl uinteger(4) or uinteger(3);
    constant boolean B = U > uinteger(18) and not (2 = 3);
    constant long L = 1000000 * 1000000 / 7;
    constant short S = -(short(40000) + 2) modulo 7;
  end;
