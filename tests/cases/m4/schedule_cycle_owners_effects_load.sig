process GEN =
  ( ! integer S3; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S0 := N + N
   | S1 := S2 + N
   | D0 := S1 $ init 0
   | S2 := N * N + D0
   | S3 := S0
   | P := pointer(ulong(N))
   | E0 := load{MA, ubyte}(P)
   | L0 :: E1 := load{MA, ubyte}(P)
   | L1 :: store{MA, ubyte}(P, ubyte(integer(E0)))
   | L2 :: E2 := load{MA, ubyte}(P)
   | I0 := indices(3)
   | I0 ^= N
   | iterate I0 of (| B0_0 := S3 + B0_0[?] + B0_0[?] | B0_1 := S1 + S1 + B0_3[?] | B0_2 := B0_2 + B0_1 + B0_1[?] | B0_3 := S2 + B0_0[?] + B0_0[?] | E3 := load{MA, ubyte}(P + I0) | store{MA, ubyte}(P + I0, ubyte(B0_0)) |) with (| B0_0 := 0 | B0_1 := 0 | B0_2 := 0 | B0_3 := 0 |) end
   | L0 --> L2
   | L1 --> L0
   | L0 --> L1
   |)
  where
    type MA = external;
    integer ZN, N, S0, S1, S2, D0, B0_0, B0_1, B0_2, B0_3;
    pointer P;
    ubyte E0, E1, E2, E3;
    label L0, L1, L2;
    [3] integer I0;
  end;
