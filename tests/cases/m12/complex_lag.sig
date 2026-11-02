process COMPLEXLAG =
  ( ? complex A; dcomplex D;
    ! complex D1, D2, D3; dcomplex E2; )
  (| D1 := A $ 1
   | D2 := A $ 2
   | D3 := A $ 3
   | E2 := D $ 2
   | A ^= D
   |)
  where
  end;
