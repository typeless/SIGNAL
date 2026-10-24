process LCO =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(3)
   | I ^= N
   | iterate I of R := Y + I end
   | Y := R + 1
   | X := R
   |)
  where
    integer ZN, N, R, Y;
    [3] integer I;
  end;
