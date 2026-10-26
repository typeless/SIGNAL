process P = ( ! integer N, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | L :: Y := N when (N modulo 3 = 0)
   | L :: W := N when (N modulo 2 = 0)
   | Z := N when ^L
   |)
  where
    integer ZN, Y, W;
    label L;
  end;
