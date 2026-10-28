process ARRDW =
  ( ? [2] integer A, B, E; boolean C, D;
    ! [2] integer W, X, Y; )
  (| W := (A when C) default (B when D) default E
   | X := ((A when C) default B) when D
   | Y := (A default B) when C
   | A ^= B ^= E ^= C ^= D
   |);
