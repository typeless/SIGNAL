process BITS =
  ( ! ubyte A, O, X, T, L, R; ushort H; ulong G; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | V := ubyte(N * 100)
   | A := V and ubyte(15)
   | O := V or ubyte(1)
   | X := V xor ubyte(170)
   | T := not V
   | L := V shl 1
   | R := V shr N
   | H := ushort(V) shl 12
   | G := ulong(V) shl (N + 60)
   |)
  where
    integer ZN, N;
    ubyte V;
  end;
