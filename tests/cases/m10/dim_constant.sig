process DIMCONSTANT =
  ( ? integer I, J;
    ! integer A, B; )
  (| X := N | X ^= I
   | A := dim(X) + size(X, 2) + I
   | B := dim(X) + J
   |)
  where
    [2, 3] integer X;
    constant [2, 3] integer N = [[1, 2, 3], [4, 5, 6]];
  end;
