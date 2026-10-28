process DECLARATIONINIT =
  ( ! [3] integer C; integer T; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, N, N]
   | B := A $
   | C := B
   | S := N $
   | T := S
   |)
  where
    integer ZN, N;
    [3] integer A;
    [3] integer B init [4, 5, 6];
    integer S init 9;
  end;
