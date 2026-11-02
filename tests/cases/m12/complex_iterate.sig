process COMPLEXITERATE =
  ( ? complex A; dcomplex D;
    ! complex R; dcomplex S, P; )
  (| I := indices(3)
   | I ^= A ^= D
   | iterate I of Q := Q[?] * A with Q := A end
   | R := Q
   | iterate I of T := T[?] + D with T := 1.0 @ -2.5 end
   | S := T
   | iterate I of U := U[?] * D with U := A end
   | P := U
   |)
  where
    complex Q;
    dcomplex T, U;
    [3] integer I;
  end;
