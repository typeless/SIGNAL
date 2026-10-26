process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N |* N
   | A := X[0]
   |)
  where
    integer ZN, N;
    [4] integer X;
  end;
