process INDICESVALUE =
  ( ? event T; ! [2, 3] integer I, J; )
  (| (I, J) := indices(2, 3)
   | I ^= J ^= T
   |)
  where
  end;
