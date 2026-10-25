process P =
  ( ? event START;
    ! integer N; )
  pragmas
    Boot {START}
  end pragmas
  (| N := 1 when START
   | E :: store{R, uinteger}(pointer(ulong(150994944)), uinteger(65))
   |)
  where
    type R = external;
    label E;
  end;
