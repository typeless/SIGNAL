process BODYDELAY =
  ( ! [3] integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := [N, N * 10, N * 100]
   | array I to 2 of
       Y[I] := (X $ init Z)[I] + X[I]
     end
   |)
  where
    integer ZN, N;
    [3] integer X;
    constant [3] integer Z = [7, 8, 9];
  end;
