process KINDS =
  ( ! integer S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := pointer(ulong(4096))
   | store{MEMORY, ubyte}(P, ubyte(N))
   | A := load{MEMORY, ubyte}(P + 1)
   | S := integer(A)
   |)
  where
    type MEMORY = external;
    integer ZN, N;
    pointer P;
    ubyte A;
  end;
