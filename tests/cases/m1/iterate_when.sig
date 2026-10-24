process F =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(2)
   | I ^= N
   | iterate I of A := (A[?] + I) when (I > 0) end
   |)
  where
    integer ZN, N;
    [2] integer I;
  end;
