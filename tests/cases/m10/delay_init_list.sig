process DELAYINITLIST =
  ( ! integer Y, Z; [2] integer W; [3] integer V, U; integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N $ 2 init [5, 6]
   | Z := N $ K init [-5, 6, 7]
   | W := N window K init [8]
   | A := [N, N * 10, -N]
   | V := A $ 1 init [[4, 5, 6]]
   | U := A $ init [7, 8, 9]
   | X := (N $ 2 init [1, 2]) $ init 4
   |)
  where
    integer ZN, N;
    [3] integer A;
    constant integer K = 2;
  end;
