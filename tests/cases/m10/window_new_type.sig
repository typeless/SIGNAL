process WINDOWNEWTYPE =
  ( ! [3] integer C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, N * 10, N * 100]
   | C := (A $ 2 init Z) window 1
   |)
  where
    integer ZN, N;
    [3] integer A;
    constant [2, 3] integer Z = [[1, 2, 3], [4, 5, 6]];
  end;
