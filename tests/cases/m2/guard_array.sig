process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := indices(4)
   | on when N modulo 2 = 0 :: (| Y := T[1] |)
   |)
  where
    integer ZN, N;
    [4] integer T;
  end;
