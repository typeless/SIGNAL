process CHARLITERAL =
  ( ! integer N; char A, B, C, D, E, F, G, H; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := 'a'
   | B := 'é'
   | C := '\xE9'
   | D := '\351'
   | E := '\n'
   | F := '\''
   | G := '"'
   | H := Q
   | A ^= B ^= C ^= D ^= E ^= F ^= G ^= H ^= N
   |)
  where
    integer ZN;
    constant char Q = '\0';
  end;
