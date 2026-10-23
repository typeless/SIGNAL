process DOWN =
  ( ! integer N, M; )
  (| N := (ZN - 3) * 1000000
   | ZN := (N / 1000000) $ init 0
   | M := -(N $ init 7)
   |)
  where
    integer ZN;
  end;
