process ELEMENTCHAINED =
  ( ? [2, 2] integer X; integer I;
    ! integer A, B; )
  (| X ^= I
   | A := X[0, 0] + I
   | B := A + X[1][1]
   | X[I, 0] --> B
   | X[0][1] --> B
   | X[1][I] --> A --> B
   |);
