process CS =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := (N modulo 2) = 0
   | Y := ((((Y $ init 0) when P) + 1) when P) default N
   |)
  where
    integer ZN, N;
    boolean P;
  end;
