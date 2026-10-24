process ARGC =
  ( ! integer COUNT; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | COUNT := integer(instruction{ARGS, 2853766112}(ulong(N)))
   |)
  where
    type ARGS = external;
    integer ZN, N;
  end;
