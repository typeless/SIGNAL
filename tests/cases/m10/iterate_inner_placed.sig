process ITERATEINNERPLACED =
  ( ! integer A, B; )
  (| I := indices(2)
   | J := indices(2)
   | iterate I of
       (| B := B[?] + I
        | iterate J of A := A[?] + J end
        |)
     with (| A := 0 | B := 0 |)
     end
   |)
  where
    [2] integer I, J;
  end;
