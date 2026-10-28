process BUNDLEEFFECT =
  ( ? integer N; ! integer T; )
  (| B.P := uinteger(N)
   | B.Q := uinteger(N + 1)
   | store{MEMORY, uinteger}(pointer(ulong(4096)), B)
   | T := N
   |)
  where
    type MEMORY = external;
    bundle (uinteger P; uinteger Q;) B;
  end;
