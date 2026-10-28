process ALONE =
  ( ! integer X, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := 1 : N
   | X := T[0]
   | Z := T[1]
   |)
  where
    integer ZN, N;
    [2] integer T;
  end;
