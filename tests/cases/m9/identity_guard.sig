process IDGUARD =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | on when (N modulo 2 = 0) :: (| X :=: N + 1 |)
   |)
  where
    integer ZN;
  end;
