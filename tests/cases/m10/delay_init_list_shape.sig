process DELAYINITLISTSHAPE =
  ( ! [3] integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, N, N]
   | Y := A $ init [4, 5]
   |)
  where
    integer ZN, N;
    [3] integer A;
  end;
