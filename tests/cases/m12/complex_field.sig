process COMPLEXFIELD =
  ( ? complex A; real X;
    ! dcomplex F; complex G; )
  (| S.C := A
   | S.D := dcomplex(A) * (1.0d0 @ 1.0d0)
   | S.R := X
   | F := S.D
   | G := S.C + (S.R @ 0.0)
   | A ^= X
   |)
  where
    type Q = struct (complex C; dcomplex D; real R;);
    Q S;
  end;
