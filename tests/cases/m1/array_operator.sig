process AOP =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := A + 1
   | X := T[0]
   |)
  where
    constant [4] integer A = [10, 20, 30, 40];
    integer ZN, N;
    [4] integer T;
  end;
