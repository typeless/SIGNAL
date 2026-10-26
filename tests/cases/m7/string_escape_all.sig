process TEXT =
  ( ! integer B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := integer(S[ZN modulo 17])
   |)
  where
    constant [17] ubyte S = "\a\b\f\n\r\t\v\\\"\'\?\%\0\7z\xfF\x9";
    integer ZN, N;
  end;
