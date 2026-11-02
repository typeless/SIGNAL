process COMPLEXAT =
  ( ? real X, Y; dreal XD, YD;
    ! complex Z; dcomplex ZD, ZM; complex ZN, ZS; )
  (| Z := X @ Y
   | ZD := XD @ YD
   | ZM := X @ YD
   | ZN := X @ -Y
   | ZS := X @ Y + 1.0 @ (-1.0)
   | X ^= XD
   |)
  where
  end;
