process P =
  ( ! integer N, Y, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N when (N modulo 2 = 0)
   | L :: Y := X + 1
   | H := ^L
   | Z := N when H
   |)
  where
    integer ZN, X;
    event H;
    label L;
  end;
