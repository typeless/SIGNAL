process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := K + N * 0
   |)
  where
    integer ZN;
    constant integer K = 2 ** 3 ** 1;
  end;
