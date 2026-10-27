process ENUMSWAPLOOP =
  ( ? integer I;
    ! [2] integer E; )
  (| K := indices(3)
   | K ^= I
   | iterate K of E := [E[?][1], E[?][0] + K] with E := BASE end
   |)
  where
    constant [2] integer BASE = [1, 2];
    [3] integer K;
  end;
