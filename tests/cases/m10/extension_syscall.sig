process EXTSY =
  ( ! [3] long C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | FIRST := N = 1
   | MAPPED := syscall{OS}(197, 0 when FIRST, 16384, 3, 4098, -1, 0)
   | P := pointer(ulong(MAPPED))
   | MARK :: store{BUF, ubyte}(P, ubyte(120))
   | C := long(K) + syscall{OS}(4, 1, P, 1, 0, 0, 0)
   | MAPPED --> MARK --> C
   | C ^= MAPPED
   |)
  where
    type OS = external;
    type BUF = external;
    constant [3] integer K = [1, 2, 3];
    integer ZN, N;
    boolean FIRST;
    long MAPPED;
    pointer P;
    label MARK;
  end;
