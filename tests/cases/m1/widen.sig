process WIDEN =
  ( ! long L; integer J; boolean C; uinteger M; short S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := 0 - N
   | U := uinteger(0 - N)
   | L := I + U
   | B := ubyte(N * 100)
   | J := N + B
   | C := U > 4294967293
   | M := U modulo uinteger(7)
   | S := B
   |)
  where
    integer ZN, N, I;
    uinteger U;
    ubyte B;
  end;
