process COUNTER =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | (| M := N * 2 |) / M
   |) / ZN, M / ZN
  where
    integer ZN, M;
  end;
