process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := MISSING(N)
   |)
  where
    integer ZN, N;
  end;
