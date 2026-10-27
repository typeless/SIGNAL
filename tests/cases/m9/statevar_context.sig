process STATECONTEXT =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | CNT ::= (CNT? + 1) when C
   | Y := CNT?
   |)
  where
    integer ZN; boolean C;
    statevar integer CNT init 0;
  end;
