process P =
  ( ! integer N, M; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | EVEN := when (N modulo 2 = 0)
   | L :: X := N when EVEN
   | on L :: (| M := N * 10 |)
   |)
  where
    integer ZN, X;
    event EVEN;
    label L;
  end;
