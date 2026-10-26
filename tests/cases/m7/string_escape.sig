process TEXT =
  ( ! integer B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := integer(S[ZN modulo 6])
   |)
  where
    constant [6] ubyte S = "a\n\"\x41\101\\";
    integer ZN, N;
  end;
