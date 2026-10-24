process INSTR =
  ( ! ulong Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := instruction{CPU, ADD_ONE}(ulong(N))
   |)
  where
    type CPU = external;
    constant long ADD_ONE = 2432697344;
    integer ZN, N;
  end;
