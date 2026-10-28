process DELAYINITSHAPE =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N $ 3 init Y0
   |)
  where
    integer ZN, N;
    constant [2] integer Y0 = [1, 2];
  end;
