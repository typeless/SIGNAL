process STRUCTOFARRAYS =
  ( ? integer N;
    ! struct ([3] integer V; integer K;) S; integer T, U; boolean B; )
  (| S.V := [N, N + 1, N * 2]
   | S.K := N - 1
   | M.A := [N, 2 * N, 3 * N]
   | M.B := [true, false, N > 2]
   | T := M[2].A + S.V[1]
   | R := M[1]
   | U := R.A
   | B := M[(N modulo 3)].B
   |)
  where
    [3] struct (integer A; boolean B;) M;
    struct (integer A; boolean B;) R;
  end;
