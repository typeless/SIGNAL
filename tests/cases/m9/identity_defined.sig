process IDENTITYDEFINED =
  ( ! integer N, X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | X := N when C
   | Y := N when C
   | X :=: Y
   |)
  where
    integer ZN; boolean C;
  end;
