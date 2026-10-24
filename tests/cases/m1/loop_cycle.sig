process LC =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(3)
   | I ^= N
   | J := indices(3)
   | J ^= N
   | iterate I of R := S + I end
   | iterate J of S := R + J end
   | X := R
   |)
  where
    integer ZN, N, R, S;
    [3] integer I, J;
  end;
