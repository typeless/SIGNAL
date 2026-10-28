process MATRIXPRODUCT =
  ( ? [2, 3] integer A; [3, 2] integer B;
    ! [2, 2] integer X; )
  (| X := A *. B
   | A ^= B
   |);
