process ARRAYINPUT =
  ( ? [3] integer V;
    ! integer S; [3] integer W; )
  (| S := V[0] + V[1] + V[2]
   | W := V
   |);
