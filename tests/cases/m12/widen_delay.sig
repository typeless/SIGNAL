process WIDENDELAY =
  ( ? dreal X;
    ! dreal Y1, Y2, Y3, Y4, Y5, Y6; )
  (| Y1 := X $ 1 init 1.5
   | Y2 := X $ init C
   | Z := X $
   | Y3 := Z
   | Y4 := X $ init -0.1
   | Y5 := X $ init 1.0e-40
   | Y6 := X $ init 0.1d0
   |)
  where
    constant real C = 0.1;
    dreal Z init 4.5;
  end;
