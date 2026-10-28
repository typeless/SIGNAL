process DELAYSWAP =
  ( ! [2] integer A, B, X2; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := B $ init A0
   | B := A $ init B0
   | A ^= N
   | X2 := X1 $
   | X1 := X $
   | X := [N, 2 * N]
   |)
  where
    integer ZN, N;
    [2] integer X, X1;
    constant [2] integer A0 = [1, 2];
    constant [2] integer B0 = [3, 4];
  end;
