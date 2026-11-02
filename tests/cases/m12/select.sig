process SELECT =
  ( ? real A; boolean B;
    ! real Z, W, I; [3] real T; dreal E; )
  (| Z := A $ init 0.5
   | W := (A when B) default Z
   | I := if B then A else -A
   | T := V next 2 : A
   | E := if B then dreal(V[0]) + 1.0d0 else -0.0d0
   | A ^= B
   |)
  where
    constant [3] real V = [1.5, -0.0, 0.0];
  end;
