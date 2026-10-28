process DELAYINITEXTRA =
  ( ! integer Y; [1] integer W; [2] integer V; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N $ 2 init Y0
   | W := N window 1 init Y0
   | V := N window 2 init Y0
   |)
  where
    integer ZN, N;
    constant [3] integer Y0 = [-2, -1, 0];
  end;
