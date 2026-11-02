process WIDENITERATE =
  ( ? real X;
    ! [2] dreal T; )
  (| I := indices(2)
   | I ^= X
   | iterate I of
       (| T[I] := X |)
     end
   |)
  where
    [2] integer I;
  end;
