process CONVERSIONS =
  ( ! short S; integer I; long L; uinteger U; integer J; short T; integer K; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := ubyte(N * 100)
   | S := B + 1000
   | I := integer(S) * 1000
   | L := long(I) * I
   | U := uinteger(0 - I)
   | J := integer(U)
   | T := short(I)
   | K := integer(N > 2)
   |)
  where
    integer ZN, N;
    ubyte B;
  end;
