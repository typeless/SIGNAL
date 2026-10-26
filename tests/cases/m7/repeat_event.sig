process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := when (N modulo 3 = 0)
   | A := T |* 3
   | Y := N when A[0]
   |)
  where
    integer ZN, N;
    event T;
    [3] event A;
  end;
