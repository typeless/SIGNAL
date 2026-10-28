process DELAYINITBLOCK =
  ( ! [2] integer D; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, -N]
   | D := A $ 2 init C
   |)
  where
    integer ZN, N;
    [2] integer A;
    constant [4] integer C = [1, 2, 3, 4];
  end;
