process RELSUB =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N when (N modulo 2 = 0)
   | X ^< N
   |)
  where
    integer ZN;
  end;
