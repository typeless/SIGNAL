process CW =
  ( ! integer Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | X := 5
   | Z := X when C
   |)
  where
    integer ZN, N, X;
    boolean C;
  end;
