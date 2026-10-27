process AFFRELPHASE =
  ( ! integer X, Y; )
  (| X := 1
   | Y := 2
   | affine_clock_relation{1, -1, 2}(X, Y)
   |);
