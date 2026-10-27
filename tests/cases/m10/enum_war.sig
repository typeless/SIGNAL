process ENUMWAR =
  ( ? integer I;
    ! [2] integer E; integer Q; )
  (| K := indices(3)
   | K ^= I
   | iterate K of (| Q := E[?][0] * 10 + E[?][1] | E := [K + 5, K + 7] |) with E := BASE end
   |)
  where
    constant [2] integer BASE = [1, 2];
    [3] integer K;
  end;
