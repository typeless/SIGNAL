process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 3, 4098, -1, 0)
   | BASE := pointer(ulong(MAPPED)) default ZBASE
   | ZBASE := BASE $
   | BASE ^= N
   | V := PEEK(BASE)
   | W :: PUT(V, ubyte(64 + N))
   | V --> W
   |)
  where
    type OS = external;
    type MEM = external;
    integer ZN;
    long MAPPED;
    pointer BASE, ZBASE, V;
    label W;
    procedure PUT = ( ? pointer B; ubyte C; ) (| store{MEM, ubyte}(B, C) |);
    process PEEK = ( ? pointer B; ! pointer R; ) (| X := load{MEM, ubyte}(B) | R := B |) where ubyte X; end;
  end;
