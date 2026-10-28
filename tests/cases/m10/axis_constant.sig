process AXISCONSTANT =
  ( ? integer K; ! [2, 3] integer I, J; )
  (| (I, J) := << 0 .. 1, 0 .. K >>
   | I ^= J ^= K
   |)
  where
  end;
