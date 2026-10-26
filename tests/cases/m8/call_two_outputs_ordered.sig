process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 3, 4098, -1, 0)
   | BASE := pointer(ulong(MAPPED)) default ZBASE
   | ZBASE := BASE $
   | BASE ^= N
   | W :: PUT(BASE, ubyte(64 + N))
   | K :: (R, S) := TWO(BASE)
   | V := WR(R)
   | U := WR(S)
   | W --> K
   | V --> U
   |)
  where
    type OS = external;
    type MEM = external;
    integer ZN;
    long MAPPED, V, U;
    pointer BASE, ZBASE, R, S;
    label W, K;
    procedure PUT = ( ? pointer B; ubyte C; ) (| store{MEM, ubyte}(B, C) |);
    node TWO = ( ? pointer B; ! pointer C, D; ) (| C := B | D := B | C --> D |);
    process WR = ( ? pointer B; ! long Q; ) (| Q := syscall{OS}(4, 1, B, 1, 0, 0, 0) |);
  end;
