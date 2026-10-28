process EXTITER =
  ( ? [3] integer A;
    ! [3] integer W; )
  (| I := indices(3)
   | I ^= A
   | iterate I of W := A + 1 end
   |)
  where
    [3] integer I;
  end;
