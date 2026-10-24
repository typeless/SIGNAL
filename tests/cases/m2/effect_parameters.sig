process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := load{MEM}(pointer(ulong(N)))
   |)
  where
    integer ZN, N;
    type MEM = external;
  end;
