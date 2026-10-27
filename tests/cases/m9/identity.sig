process IDENTITY =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N when (N modulo 2 = 0)
   | Y :=: X + 1
   |)
  where
    integer ZN, X;
  end;
