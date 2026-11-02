process WIDENSEED =
  ( ? dreal X; real H;
    ! dreal A, B; )
  (| I := indices(2)
   | I ^= X ^= H
   | iterate I of R := R[?] + X with R := 1.5 end
   | iterate I of S := S[?] + X with S := H end
   | A := R
   | B := S
   |)
  where
    dreal R, S;
    [2] integer I;
  end;
