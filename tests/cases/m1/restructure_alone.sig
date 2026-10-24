process ALONE =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := 1 : N
   | X := T[0]
   |)
  where
    integer ZN, N;
    [2] integer T;
  end;
