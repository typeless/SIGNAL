process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 3, 4098, -1, 0)
   | BASE := pointer(ulong(MAPPED)) default ZBASE
   | ZBASE := BASE $
   | BASE ^= N
   | W :: PUT(BASE, ubyte(64 + N))
   | V := WR(BASE)
   | W --> V
   |)
  where
    type OS = external;
    type MEM = external;
    integer ZN;
    long MAPPED, V;
    pointer BASE, ZBASE;
    label W;
    action PUT = ( ? pointer B; ubyte C; ) (| store{MEM, ubyte}(B, C) |);
    process WR = ( ? pointer B; ! long R; ) (| R := syscall{OS}(4, 1, B, 1, 0, 0, 0) |);
  end;
