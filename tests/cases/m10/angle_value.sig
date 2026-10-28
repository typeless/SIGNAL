process ANGLEVALUE =
  ( ? event T; ! [2, 3] integer I, J; )
  (| (I, J) := << 2 .. 3, 4 .. 6 >>
   | I ^= J ^= T
   |)
  where
  end;
