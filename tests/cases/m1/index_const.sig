process ICONST =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := A[4] + N
   |)
  where
    constant integer SIZE = 4;
    constant [SIZE] integer A = [10, 20, 30, 40];
    integer ZN, N;
  end;
