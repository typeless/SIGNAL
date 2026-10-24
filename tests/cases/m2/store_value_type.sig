process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | store{MEM, ubyte}(pointer(ulong(N)), N)
   | Y := N
   |)
  where
    integer ZN, N;
    type MEM = external;
  end;
