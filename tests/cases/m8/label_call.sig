process P =
  ( ! integer N, Y, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := N modulo 3 /= 0
   | L :: Y := HALF(N when B)
   | H := ^L
   | Z := N when H
   |)
  where
    integer ZN;
    boolean B;
    event H;
    label L;
    process HALF = ( ? integer A; ! integer R; ) (| R := A when A modulo 2 = 0 |);
  end;
