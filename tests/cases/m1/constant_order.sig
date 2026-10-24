process CORDER =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := A[0] + N
   |)
  where
    integer ZN, N;
    constant [SIZE] integer A = [1, 2, 3];
    constant integer SIZE = 3;
  end;
