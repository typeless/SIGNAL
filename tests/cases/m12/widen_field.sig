process WIDENFIELD =
  ( ? real X; integer I;
    ! dreal F; )
  (| S.R[I] := X
   | S.Z := 1.0d0
   | F := S.R[I]
   | X ^= I
   |)
  where
    type Q = struct ([2] dreal R; dreal Z;);
    Q S;
  end;
