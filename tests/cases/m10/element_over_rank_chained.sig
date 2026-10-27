process OVERRANK =
  ( ? [2, 2] integer X; integer I;
    ! integer A, B; )
  (| A := X[0, 0] + I
   | B := A + 1
   | X[0][1][0] --> B
   |)
  where
  end;
