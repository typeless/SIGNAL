process STATEASSIGNED =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | CNT := N
   | Y := CNT? when N > 0
   |)
  where
    integer ZN;
    statevar integer CNT init 0;
  end;
