process RANGEOUTPUTINDEX =
  ( ? event T; ! [3] integer J; integer A; )
  (| J := 0 .. 2
   | J ^= T
   | iterate J of
       A := A[?] * 10 + J
     with A := 0
     end
   |);
