process RANKOK =
  ( ? [2, 2] integer X; integer I;
    ! integer A, B; )
  (| A := X[0, 0] + I
   | B := A + 1
   | X[0, f(1, 0)] --> B
   | X[0][1] --> B
   | X[1] --> B
   |)
  where
    function f = ( ? integer P, Q; ! integer R; ) (| R := P + Q |);
  end;
