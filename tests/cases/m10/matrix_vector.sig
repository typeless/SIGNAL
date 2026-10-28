process MATRIXVECTOR =
  ( ? [2, 3] integer A; [3] integer V; [2] integer W;
    ! [2] integer Y; [3] integer Z; integer D; )
  (| Y := A *. V
   | Z := W *. A
   | D := V *. V
   | A ^= V ^= W
   |);
