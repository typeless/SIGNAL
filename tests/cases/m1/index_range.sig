process RANGE =
  ( ! integer K, X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N - 2
   | X := A[K]
   | T := A next K : N
   | Y := T[0] + T[1] + T[2] + T[3]
   |)
  where
    integer ZN, N;
    constant [4] integer A = [10, 20, 30, 40];
    [4] integer T;
  end;
