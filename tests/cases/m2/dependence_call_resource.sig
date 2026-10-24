process P =
  ( ! integer N, V; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 3, 4098, -1, 0)
   | BASE := pointer(ulong(MAPPED)) default ZBASE
   | ZBASE := BASE $
   | BASE ^= N
   | W :: PUT(BASE, ubyte(64 + N))
   | V := GET(BASE)
   | W --> V
   |)
  where
    type OS = external;
    type MEM = external;
    integer ZN;
    long MAPPED;
    pointer BASE, ZBASE;
    label W;
    procedure PUT = ( ? pointer B; ubyte C; ) (| store{MEM, ubyte}(B, C) |);
    process GET = ( ? pointer B; ! integer R; ) (| R := integer(load{MEM, ubyte}(B)) |);
  end;
