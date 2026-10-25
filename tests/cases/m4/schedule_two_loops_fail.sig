process TWOLOOPS =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(3)
   | I ^= N
   | J := indices(3)
   | J ^= N
   | iterate J of
       (| Q := R + J
        | R := Q + 1
        |)
     end
   | iterate I of
       (| B := A + I
        | A := B + 1
        |)
     end
   | X := A + Q
   |)
  where
    integer ZN, N, A, B, Q, R;
    [3] integer I, J;
  end;
