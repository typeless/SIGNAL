process MINCLOCKNAME =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | min_clock(N + 1)
   |)
  where
    integer ZN;
  end;
