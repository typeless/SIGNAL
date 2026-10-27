process AFFRELDEF =
  ( ! integer X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | X := N when C
   | Y := 2
   | affine_clock_relation{2, 0, 3}(X, Y)
   |)
  where
    integer ZN, N; boolean C;
  end;
