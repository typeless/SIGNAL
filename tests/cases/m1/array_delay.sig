process ADELAY =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := T $ next 0 : N
   | X := T[0]
   |)
  where
    integer ZN, N;
    [4] integer T;
  end;
