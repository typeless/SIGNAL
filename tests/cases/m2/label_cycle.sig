process LCYCLE =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | BASE := pointer(ulong(N))
   | FIRST :: store{MEM, ubyte}(BASE, ubyte(N))
   | SECOND :: store{MEM, ubyte}(BASE + 1, ubyte(N))
   | FIRST --> SECOND
   | SECOND --> FIRST
   |)
  where
    type MEM = external;
    integer ZN;
    pointer BASE;
    label FIRST, SECOND;
  end;
