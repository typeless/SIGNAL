process ARRAYSUBMODELOUTPUT =
  ( ? integer I;
    ! [3] integer D; integer E; )
  (| X := N next I : I * 10
   | D := SCALE(X, 2)
   | Z := SCALE(N, I)
   | E := Z[2]
   |)
  where
    [3] integer X, Z;
    constant [3] integer N = [1, 2, 3];
    function SCALE = ( ? [3] integer Q; integer K; ! [3] integer R; )
      (| R := Q next 0 : Q[0] * K |);
  end;
