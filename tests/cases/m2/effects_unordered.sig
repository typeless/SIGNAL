process RACE =
  ( ! )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := pointer(ulong(N))
   | store{MEMORY, ubyte}(P, ubyte(1))
   | store{MEMORY, ubyte}(P, ubyte(2))
   |)
  where
    type MEMORY = external;
    integer ZN, N;
    pointer P;
  end;
