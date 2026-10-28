process STRUCTELEMENTEQ =
  ( ? integer N;
    ! boolean F; )
  (| M.A := [N, N * 2]
   | M.B := [N + 1, N + 2]
   | W.A := [N, N * 2]
   | W.B := [N + 1, 0]
   | F := M[0] == W[0]
   |)
  where
    [2] struct (integer A; integer B;) M, W;
  end;
