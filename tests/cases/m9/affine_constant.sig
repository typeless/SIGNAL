process AFFCONST =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := affine_sample{PHASE, PERIOD}(N)
   |)
  where
    integer ZN;
    constant integer PHASE = 3;
    constant integer PERIOD = 2;
  end;
