process STATEOVERLAP =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | D := N modulo 3 = 0
   | CNT ::= (CNT? + 1) when C
   | CNT ::= (CNT? + 2) when D
   | Y := CNT? when N > 0
   |)
  where
    integer ZN; boolean C, D;
    statevar integer CNT init 0;
  end;
