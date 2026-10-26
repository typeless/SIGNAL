process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := when (N modulo 2 = 0)
   | A := T |* 3
   | Y := N when A[1]
   |)
  where
    integer ZN, N;
    event T;
    [3] event A;
  end;
