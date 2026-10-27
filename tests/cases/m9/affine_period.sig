process AFFPERIOD =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := affine_sample{0, 0}(N)
   |)
  where
    integer ZN;
  end;
