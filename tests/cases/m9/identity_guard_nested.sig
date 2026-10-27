process IDGUARDNEST =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | on when (N modulo 2 = 0) :: (| on when (N modulo 4 = 0) :: (| X :=: N + 1 |) | Y := N |)
   |)
  where
    integer ZN, Y;
  end;
