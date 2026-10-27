process MINCLOCKFIXED =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | min_clock(N)
   |)
  where
    integer ZN;
  end;
