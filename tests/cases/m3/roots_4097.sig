process ROOTS =
  ( ! integer X; )
  (| X := 1 | Z := K3() |)
  where
    integer Z;
    process K0 = ( ! integer O; ) (| O := 1 |);
    process K1 = ( ! integer O; ) (| O := K0() | U0 := K0() | U1 := K0() | U2 := K0() | U3 := K0() | U4 := K0() | U5 := K0() | U6 := K0() | U7 := K0() | U8 := K0() | U9 := K0() | U10 := K0() | U11 := K0() | U12 := K0() | U13 := K0() | U14 := K0() |) where integer U0, U1, U2, U3, U4, U5, U6, U7, U8, U9, U10, U11, U12, U13, U14; end;
    process K2 = ( ! integer O; ) (| O := K1() | U0 := K1() | U1 := K1() | U2 := K1() | U3 := K1() | U4 := K1() | U5 := K1() | U6 := K1() | U7 := K1() | U8 := K1() | U9 := K1() | U10 := K1() | U11 := K1() | U12 := K1() | U13 := K1() | U14 := K1() |) where integer U0, U1, U2, U3, U4, U5, U6, U7, U8, U9, U10, U11, U12, U13, U14; end;
    process K3 = ( ! integer O; ) (| O := K2() | U0 := K2() | U1 := K2() | U2 := K2() | U3 := K2() | U4 := K2() | U5 := K2() | U6 := K2() | U7 := K2() | U8 := K2() | U9 := K2() | U10 := K2() | U11 := K2() | U12 := K2() | U13 := K2() | U14 := K2() |) where integer U0, U1, U2, U3, U4, U5, U6, U7, U8, U9, U10, U11, U12, U13, U14; end;
  end;
