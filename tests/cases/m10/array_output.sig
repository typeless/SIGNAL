process ARRAYOUTPUT =
  ( ? integer I;
    ! integer A; [3] integer T; boolean B; [2, 2] integer M; )
  (| A := I * 10
   | T := V next I : A
   | B := I > 0
   | M := N[I]
   |)
  where
    constant [3] integer V = [5, 6, 7];
    constant [3, 2, 2] integer N = [[[1, 2], [3, 4]], [[5, 6], [7, 8]], [[9, 10], [11, 12]]];
  end;
