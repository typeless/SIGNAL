process DELAYINDEX =
  ( ! integer E, F; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, 10 * N, 100 * N]
   | E := (A $ init A0)[N modulo 3]
   | F := (A window 3)[2, N modulo 3]
   |)
  where
    integer ZN, N;
    [3] integer A;
    constant [3] integer A0 = [7, 8, 9];
  end;
