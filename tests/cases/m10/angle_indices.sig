process ANGLE =
  ( ! integer A; )
  (| I := indices(2)
   | J := indices(3)
   | iterate << I, J >> of
       A := A[?] * 10 + I * 3 + J
     with A := 0
     end
   |)
  where
    [2] integer I;
    [3] integer J;
  end;
