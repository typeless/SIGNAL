process AFFUNSAMPLE =
  ( ! integer Y; )
  (| X1 := 1
   | X2 := 2
   | Y := affine_unsample{2, 0}(X1, X2)
   |)
  where
    integer X1, X2;
  end;
