process NESTED =
  ( ! integer A, B; )
  (| I := indices(2)
   | J := indices(3)
   | iterate I of
       iterate J of
         (| A := A[?] * 10 + I * 3 + J
          | B := B[?] + I * J
          |)
       end
     with (| A := 0 | B := 0 |)
     end
   |)
  where
    [2] integer I;
    [3] integer J;
  end;
