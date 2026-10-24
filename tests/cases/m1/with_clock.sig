process WC =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(2)
   | I ^= N
   | iterate I of R := R[?] + I with R := N when (N > 2) end
   | A := R
   |)
  where
    integer ZN, N, R;
    [2] integer I;
  end;
