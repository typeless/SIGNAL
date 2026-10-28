process DELAYINITLISTRAGGED =
  ( ! [2] integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, N]
   | Y := A $ 2 init [[1, 2], [3]]
   |)
  where
    integer ZN, N;
    [2] integer A;
  end;
