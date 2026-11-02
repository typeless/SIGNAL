process COMPLEXARRAYWIDEN =
  ( ? complex A; integer I;
    ! [2] dcomplex T, U, P, D; )
  (| T := Z next I : A * A
   | Z := [A, 0.1 @ 0.0]
   | U := I : A
   | P[I] := A
   | D := [W[0], A]
   | A ^= I
   |)
  where
    [2] dcomplex Z;
    constant [2] dcomplex W = [1.0d0 @ 2.0d0, 3.0d0 @ 4.0d0];
  end;
