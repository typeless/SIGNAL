process ARRAYNEIEEE =
  ( ? [2] real V, W; [2] dreal X, Y; [2] complex P, Q; [2] dcomplex R, S;
    ! boolean A, B, C, D, E, F; )
  (| A := not (V == W)
   | B := not (X == Y)
   | C := not (P == Q)
   | D := not (R == S)
   | M.F := V
   | M.G := [1, 2]
   | N.F := W
   | N.G := [1, 2]
   | E := not (M == N)
   | T := (V[0], 1)
   | U := (W[0], 1)
   | F := not (T == U)
   | V ^= W ^= X ^= Y ^= P ^= Q ^= R ^= S
   |)
  where
    [2] struct (real F; integer G;) M, N;
    struct (real F; integer G;) T, U;
  end;
