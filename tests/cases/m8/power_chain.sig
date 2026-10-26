process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N ** 2 ** 3
   |)
  where
    integer ZN;
  end;
