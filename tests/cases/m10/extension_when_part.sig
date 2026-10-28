process EXTWHEN =
  ( ? [3] integer A; boolean C;
    ! [3] integer W; )
  (| W := (A + 1) when C
   | A ^= C
   |);
