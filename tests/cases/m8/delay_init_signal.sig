process P =
  ( ! integer Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Z := N $ init (N + 1)
   |)
  where
    integer ZN, N;
  end;
