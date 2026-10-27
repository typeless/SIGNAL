process CR =
  ( ! integer Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | Y := N when C
   | X := 5
   | Z := Y default X
   |)
  where
    integer ZN, N, Y, X;
    boolean C;
  end;
