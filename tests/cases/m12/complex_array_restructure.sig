process COMPLEXARRAYRESTRUCTURE =
  ( ? complex A, B; integer I;
    ! [3] complex P, R; )
  (| P[I] := A
   | R := I : B
   | A ^= B ^= I
   |)
  where
  end;
