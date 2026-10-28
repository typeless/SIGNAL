process WINDOWARRAY =
  ( ! [3, 2] integer Y; integer E; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, -N]
   | Y := A window 3 init Y0
   | E := (A window 2)[0, 1]
   |)
  where
    integer ZN, N;
    [2] integer A;
    constant [2, 2] integer Y0 = [[5, 6], [7, 8]];
  end;
