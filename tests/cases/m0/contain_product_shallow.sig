process PRODSHALLOW =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N > 2
   | D := N modulo 2 = 0
   | X := N when D
   | Y := (X when C) default 0
   | Y ^= when C
   |)
  where
    integer ZN, X;
    boolean C, D;
  end;
