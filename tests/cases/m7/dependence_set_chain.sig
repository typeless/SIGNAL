process DCHAIN =
  ( ! long X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 3, 4098, -1, 0)
   | BASE := pointer(ulong(MAPPED)) default ZBASE
   | ZBASE := BASE $
   | BASE ^= N
   | A :: store{MEMORY, long}(BASE, long(N) * 10)
   | B :: X := load{MEMORY, long}(BASE)
   | C :: store{SCRATCH, long}(BASE + 8, long(N))
   | D :: Y := load{SCRATCH, long}(BASE + 8)
   | A --> {B, C} --> D
   |)
  where
    type OS = external;
    type MEMORY = external;
    type SCRATCH = external;
    integer ZN, N;
    long MAPPED;
    pointer BASE, ZBASE;
    label A, B, C, D;
  end;
