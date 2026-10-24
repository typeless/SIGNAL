process F =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(2)
   | I ^= N
   | iterate I of (| A := B + I | B := A + 1 |) end
   |)
  where
    integer ZN, N;
    [2] integer I;
    integer B;
  end;
