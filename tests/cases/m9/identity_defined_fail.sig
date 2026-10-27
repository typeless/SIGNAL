process IDENTITYDEFINEDFAIL =
  ( ! integer N, X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | D := N > 2
   | X := N when C
   | Y := N when D
   | X :=: Y
   |)
  where
    integer ZN; boolean C, D;
  end;
