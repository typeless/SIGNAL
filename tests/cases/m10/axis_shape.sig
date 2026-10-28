process AXISSHAPE =
  ( ? event T; ! [3, 2] integer I, J; )
  (| (I, J) := indices(2, 3)
   | I ^= J ^= T
   |)
  where
  end;
