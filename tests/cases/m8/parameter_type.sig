process P =
  ( ? event START; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| DRIVER{A, BASE_A}(START)
   | DRIVER{B, BASE_B}(START)
   |)
  where
    type A = external;
    type B = external;
    constant ulong BASE_A = ulong(536936448);
    constant ulong BASE_B = BASE_A + ulong(4);
    process DRIVER = { type R; ulong BASE; } ( ? event GO; )
      (| store{R, uinteger}(pointer(BASE) when GO, uinteger(1)) |);
  end;
