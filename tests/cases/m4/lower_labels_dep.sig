process P =
  ( ! integer Y, Z; )
  (| L :: (| N := ZN + 1 | ZN := N $ init 0 |)
   | M :: Y := N
   | Z := ZN + 2
   | L --> M
   | M --> Z
   | Z --> L
   |)
  where
    integer ZN, N;
    label L, M;
  end;
