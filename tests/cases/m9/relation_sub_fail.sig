process RELSUBFAIL =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N when (N modulo 2 = 0)
   | N ^< X
   |)
  where
    integer ZN;
  end;
