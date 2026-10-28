process INITLAGSHAPE =
  ( ! [3] integer C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, N, N]
   | B := A $ 2
   | C := B
   |)
  where
    integer ZN, N;
    [3] integer A;
    [3] integer B init [4, 5, 6];
  end;
