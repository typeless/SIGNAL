process NULLCLOCKASSUMED =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N < 0
   | X := N when C
   | X ^= ^0
   | assert(not C)
   |)
  where
    integer ZN; boolean C;
  end;
