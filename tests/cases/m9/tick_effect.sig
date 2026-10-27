process TICKEFFECT =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 3, 4098, -1, 0)
   | BASE := pointer(ulong(MAPPED)) default ZBASE
   | ZBASE := BASE $
   | BASE ^= N
   | X := N
   | C := N > 2
   | H := when (N modulo 2 = 0)
   | on H :: (| Y := X when C | W :: store{MEM, ubyte}(BASE, ubyte(64 + N)) |)
   |)
  where
    type OS = external; type MEM = external;
    integer ZN, X; long MAPPED; pointer BASE, ZBASE; boolean C; event H; label W;
  end;
