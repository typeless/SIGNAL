process AFFRELVIRT =
  ( ? event START, TICK;
    ! integer X, Y; )
  pragmas
    Boot {START}
    Interrupt {TICK} "27"
  end pragmas
  (| X := 1
   | Y := 2
   | affine_clock_relation{2, 0, 3}(X, Y)
   |);
