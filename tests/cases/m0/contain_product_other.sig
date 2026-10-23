process PRODOTHER =
  ( ! integer N, Y; boolean C3; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C3 := N modulo 3 = 0
   | X := N when (N modulo 2 = 0)
   | P := X when C3
   | Y := P default 0
   | Y ^= N when C3
   |)
  where
    integer ZN, X, P;
  end;
