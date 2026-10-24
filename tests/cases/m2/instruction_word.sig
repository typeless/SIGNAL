process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := long(instruction{MEM, 4294967296}(ulong(N)))
   |)
  where
    integer ZN, N;
    type MEM = external;
  end;
