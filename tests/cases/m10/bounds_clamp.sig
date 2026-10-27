process BOUNDSCLAMP =
  ( ? integer I, J, K;
    ! integer A, B, C; long D; ulong E; )
  (| I ^= J ^= K
   | A := bounds(I, 0, 10)
   | B := bounds(I, J, K)
   | C := integer(bounds(ubyte(I), ubyte(3), ubyte(200)))
   | D := bounds(long(I) * long(1000000000), J, long(4000000000))
   | E := bounds(ulong(I) * ulong(4000000000000000000), ulong(J), ulong(-8446744073709551616))
   |);
