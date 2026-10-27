process DIMSIZE =
  ( ? integer I;
    ! integer A, B, C, D, E, F; )
  (| A := dim(M) + I
   | B := size(M, 1) + I
   | C := size(M, 2) + I
   | D := size(M, 3) * I
   | E := size(V) + dim(I) * I
   | F := dim(V) + size(M) + size(G, 2) + I
   |)
  where
    constant [2, 3, 4] integer M = [[[0, 1, 2, 3], [10, 11, 12, 13], [20, 21, 22, 23]], [[100, 101, 102, 103], [110, 111, 112, 113], [120, 121, 122, 123]]];
    constant [5] integer V = [1, 2, 3, 4, 5];
    constant [2] [7] integer G = [[1, 1, 1, 1, 1, 1, 1], [0, 0, 0, 0, 0, 0, 0]];
  end;
