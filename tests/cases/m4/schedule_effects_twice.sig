process TWICE =
  ( ! integer A, B; )
  (| A := WRITER(1)
   | B := WRITER(2)
   |)
  where
    type MEM = external;
    process WRITER =
      ( ? integer V; ! integer N; )
      (| N := ZN + V
       | ZN := N $ init 0
       | BASE := pointer(ulong(N))
       | FIRST :: store{MEM, ubyte}(BASE, ubyte(N))
       | SECOND :: store{MEM, ubyte}(BASE + 1, ubyte(N))
       | FIRST --> SECOND
       | SECOND --> FIRST
       |)
      where
        integer ZN;
        pointer BASE;
        label FIRST, SECOND;
      end;
  end;
