process AFFPHASE =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := affine_sample{-1, 3}(N)
   |)
  where
    integer ZN;
  end;
