process DEPENDENCEWHEN =
  ( ! long V; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 3, 4098, -1, 0)
   | BASE := pointer(ulong(MAPPED)) default ZBASE
   | ZBASE := BASE $
   | BASE ^= N
   | W :: store{MEMORY, long}(BASE, long(N) * 10)
   | V := load{MEMORY, long}(BASE)
   | C := N > 0
   | {W --> V} when C
   |)
  where
    type OS = external;
    type MEMORY = external;
    integer ZN, N; boolean C;
    long MAPPED;
    pointer BASE, ZBASE;
    label W;
  end;
