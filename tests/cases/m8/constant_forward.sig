process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N
   |)
  where
    integer ZN, N;
    constant integer A = B + 1, B = 2;
  end;
