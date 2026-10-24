process BYTES =
  ( ! ubyte X; ulong Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := B[N modulo 4]
   | Y := BIG - ulong(N)
   |)
  where
    integer ZN, N;
    constant [4] ubyte B = [ubyte(200), ubyte(0), ubyte(-1), ubyte(65)];
    constant ulong BIG = ulong(-1);
  end;
