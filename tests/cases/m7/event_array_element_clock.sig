process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := when (N modulo 4 = 1)
   | A := T |* 3
   | Y := N when T
   | Y ^= A[2]
   |)
  where
    integer ZN, N;
    event T;
    [3] event A;
  end;
