process STRUCTARRAYSIZE =
  ( ? integer N;
    ! integer O, P, Q; boolean E, F; )
  (| M.A := [[N, 1, 2], [3, 4, 5]]
   | M.B := [[N, 0, 0], [0, 0, N]]
   | W.A := [[N, 1, 2], [3, 4, 5]]
   | W.B := [[1, 0, 0], [0, 0, 1]]
   | O := size(M) + N
   | P := size(M, 2) * N
   | Q := dim(M) + N
   | E := M == W
   | F := M.A == W.A
   |)
  where
    [2, 3] struct (integer A; integer B;) M, W;
  end;
