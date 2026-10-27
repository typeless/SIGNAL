process ARRAYFORMAL =
  ( ? integer I;
    ! integer S, U, W; )
  (| X := N next I : I * 10
   | S := SUM(X)
   | U := X[0]
   | W := FIRST(X) + SUM(N)
   |)
  where
    [3] integer X;
    constant [3] integer N = [1, 2, 3];
    function SUM = ( ? [3] integer Q; ! integer R; ) (| R := Q[0] + Q[1] + Q[2] |);
    function FIRST = ( ? [3] integer Q; ! integer R; ) (| P := Q next 0 : 100 | R := P[0] + Q[0] |) where [3] integer P; end;
  end;
