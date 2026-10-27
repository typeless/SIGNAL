process CHAINEDRANK3 =
  ( ? integer I, J, K;
    ! integer A, B, C; [3] integer V; )
  (| I ^= J ^= K
   | A := T[I][J][K]
   | B := T[I, J][K]
   | C := T[I][J, K]
   | V := T[I][J]
   |)
  where
    constant [2, 2, 3] integer T = [[[1, 2, 3], [4, 5, 6]], [[7, 8, 9], [10, 11, 12]]];
  end;
