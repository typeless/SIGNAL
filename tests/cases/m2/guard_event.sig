process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | on N modulo 2 = 0 :: (| Y := N |)
   |)
  where
    integer ZN, N;
  end;
