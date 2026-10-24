process CCOUNT =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := A[0] + N
   |)
  where
    integer ZN, N;
    constant [3] integer A = [1, 2, 3, 4];
  end;
