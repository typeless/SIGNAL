process SCALE = { integer K; }
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N * K
   |)
  where
    integer ZN, N;
  end;
