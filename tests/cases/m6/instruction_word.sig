process WORD =
  ( ? event START;
    ! ulong NEXT_VALUE; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| NEXT_VALUE := instruction{CPU, ADD_ONE}(ulong(41) when START) |)
  where
    type CPU = external;
    constant ulong ADD_ONE = ulong(4043309057);
  end;
