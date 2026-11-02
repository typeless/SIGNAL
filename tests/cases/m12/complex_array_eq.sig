process COMPLEXARRAYEQ =
  ( ? [2] complex V, W;
    ! boolean A, B; [2] boolean P; )
  (| A := V == W
   | B := V == C
   | P := V = W
   | V ^= W
   |)
  where
    constant [2] complex C = [1.0 @ 2.0, 3.0 @ 4.0];
  end;
