process DIM2ACCESS =
  ( ? integer I, J;
    ! integer A, B; )
  (| I ^= J
   | A := M[I, J] + M[1 - I, 2 - J]
   | B := integer(G[J, I + 0])
   |)
  where
    constant [2, 3] integer M = [[1, 2, 3], [4, 5, 6]];
    constant [3, 2] ubyte G = [[ubyte(7), ubyte(8)], [ubyte(9), ubyte(10)], [ubyte(11), ubyte(12)]];
  end;
