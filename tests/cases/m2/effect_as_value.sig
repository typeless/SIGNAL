process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := long(store{MEM, long}(pointer(ulong(N)), N))
   |)
  where
    integer ZN, N;
    type MEM = external;
  end;
