process RANGEOUTPUT =
  ( ? event T; ! [3] integer I; )
  (| I := 3 .. 5
   | I ^= T
   |);
