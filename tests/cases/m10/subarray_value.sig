process SUBARRAYVALUE =
  ( ? integer I;
    ! integer A, B, C; )
  (| R := M[I]
   | A := R[0]
   | B := R[1]
   | S := N[I, I - 1]
   | C := S[0] + S[1]
   |)
  where
    [2] integer R, S;
    constant [3, 2] integer M = [[1, 2], [3, 4], [5, 6]];
    constant [2, 3, 2] integer N = [[[1, 2], [3, 4], [5, 6]], [[7, 8], [9, 10], [11, 12]]];
  end;
