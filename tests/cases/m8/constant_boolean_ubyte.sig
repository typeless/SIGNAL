process P =
  ( ! integer N; ubyte Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := K + ubyte(N) * ubyte(0)
   |)
  where
    integer ZN;
    constant ubyte K = (3 > 2);
  end;
