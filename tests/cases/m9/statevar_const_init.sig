process P13 =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | CNT ::= (CNT? + 1) when C
   | Y := CNT? when N > 0
   |)
  where
    constant integer K = 7;
    integer ZN; boolean C;
    statevar integer CNT init K;
  end;
