process ARRWD =
  ( ? [2] integer A, B; boolean C, D;
    ! [2] integer T, U, W; )
  (| T := A when C default B
   | U := A when C
   | W := (A when C) default (B when D)
   | A ^= B ^= C ^= D
   |);
