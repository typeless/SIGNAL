process GEN =
  ( ! integer S1; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S1 := S1 + N
   | P := pointer(ulong(N))
   | L1 :: store{MA, ubyte}(P, ubyte(5))
   | L2 :: store{MA, ubyte}(P, ubyte(6))
   | L1 --> L2
   | L2 --> L1
   |)
  where
    type MA = external;
    integer ZN, N;
    pointer P;
    label L1, L2;
  end;
