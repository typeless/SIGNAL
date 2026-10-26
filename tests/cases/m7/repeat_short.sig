process P =
  ( ! integer A, B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N |* 3
   | A := X[0]
   | B := X[3]
   |)
  where
    integer ZN, N;
    [4] integer X;
  end;
