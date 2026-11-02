process WIDENRESTRUCTURE =
  ( ? real X; integer I;
    ! [3] dreal T, P; )
  (| T := I : X
   | P[I] := X
   | X ^= I
   |)
  where
  end;
