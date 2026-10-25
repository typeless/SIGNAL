process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := integer(load{MEM, NOPE}(pointer(ulong(N))))
   |)
  where
    integer ZN, N;
    type MEM = external;
  end;
