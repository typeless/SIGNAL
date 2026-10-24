process POINTERS =
  ( ! ulong A, D; boolean LT, EQ; uinteger W; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := pointer(ulong(N) * ulong(4096))
   | Q := P + 16
   | R := Q - 32
   | A := ulong(R)
   | D := ulong(Q) - ulong(P)
   | LT := R < P
   | EQ := R + 16 = P
   | W := uinteger(Q)
   |)
  where
    integer ZN, N;
    pointer P, Q, R;
  end;
