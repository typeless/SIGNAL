process ITYPE =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N > 0
   | X := A[C]
   |)
  where
    constant [4] integer A = [10, 20, 30, 40];
    integer ZN, N;
    boolean C;
  end;
