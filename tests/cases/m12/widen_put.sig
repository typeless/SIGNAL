process WIDENPUT =
  ( ? real X; dreal Y;
    ! [2] dreal T1, T2, T3; [2, 2] dreal M; )
  (| T1 := [X, X]
   | T2 := [0.1, Y]
   | T3 := [Y, X]
   | M := [[X, 0.1], [Y, X]]
   | X ^= Y
   |)
  where
  end;
