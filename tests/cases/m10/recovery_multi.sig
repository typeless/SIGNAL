process RECOVERYMULTI =
  ( ? integer I, J, K;
    ! integer A, B, C, D; )
  (| I ^= J ^= K
   | A := M[I, J] \\ 9
   | B := M[I][J] \\ 9
   | C := T[I, J, K] \\ -1
   | D := T[I][J][K] \\ K
   |)
  where
    constant [2, 3] integer M = [[1, 2, 3], [4, 5, 6]];
    constant [2, 2, 3] integer T = [[[1, 2, 3], [4, 5, 6]], [[7, 8, 9], [10, 11, 12]]];
  end;
