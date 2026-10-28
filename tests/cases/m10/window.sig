process WINDOWS =
  ( ! [3] integer Y; [1] integer W; [2] short S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N window 3 init Y0
   | W := N window 1
   | S := short(N) window 2
   |)
  where
    integer ZN, N;
    constant [2] integer Y0 = [-1, 0];
  end;
