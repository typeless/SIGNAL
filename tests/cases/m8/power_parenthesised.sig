process P =
  ( ! integer N, Y, Z, W; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := (N ** 3) ** 2
   | Z := N ** (2)
   | W := K + N * 0
   |)
  where
    integer ZN;
    constant integer K = (2 ** 2) ** 3;
  end;
