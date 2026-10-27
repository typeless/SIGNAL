process CONCAT =
  ( ? [2] integer X; [1] integer Y; [1, 2] integer P;
    ! [3] integer Z; [2, 2] integer W; )
  (| Z := X |+ Y
   | W := P |+ P
   | P ^= X
   |)
  where
  end;
