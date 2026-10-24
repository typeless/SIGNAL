process MEMORY =
  ( ! long A; ulong B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 3, 4098, -1, 0)
   | BASE := pointer(ulong(MAPPED)) default ZBASE
   | ZBASE := BASE $
   | BASE ^= N
   | FIRST :: store{MEM, short}(BASE, ALL)
   | SECOND :: store{MEM, ubyte}(BASE, ubyte(N))
   | A := load{MEM, short}(BASE)
   | B := load{MEM, ulong}(BASE)
   | FIRST --> SECOND --> A --> B
   |)
  where
    type OS = external;
    type MEM = external;
    constant short ALL = -1;
    integer ZN, N;
    long MAPPED;
    pointer BASE, ZBASE;
    label FIRST, SECOND;
  end;
