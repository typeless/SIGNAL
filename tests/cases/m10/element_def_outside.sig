process ELEMENTDEFOUTSIDE =
  ( ? integer I;
    ! [3] integer X; [2, 2] integer M; integer A; )
  (| X[1] := I
   | M[1, 0] := I + 1
   | A := X[1] + M[1][0]
   |)
  where
  end;
