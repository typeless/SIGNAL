process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | load{MEM, long}(pointer(ulong(N)))
   | Y := N
   |)
  where
    integer ZN, N;
    type MEM = external;
  end;
