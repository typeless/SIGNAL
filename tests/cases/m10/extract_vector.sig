process EXTRACTVECTOR =
  ( ? [3] integer P, Q;
    ! [3] integer W; [2] integer U; )
  (| W := M[P, Q]
   | U := V[0 .. 1]
   | V := P
   |)
  where
    constant [3, 3] integer M = [[1, 2, 3], [4, 5, 6], [7, 8, 9]];
    [3] integer V;
  end;
