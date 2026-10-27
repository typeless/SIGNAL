process CHAINEDACCESS =
  ( ? integer I, J;
    ! integer A, B; )
  (| I ^= J
   | A := M[I, J]
   | B := M[I][J]
   |)
  where
    constant [2, 3] integer M = [[1, 2, 3], [4, 5, 6]];
  end;
