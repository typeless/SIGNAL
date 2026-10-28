process ENUMSEQUENTIAL =
  ( ? event TICK; ! [4] integer T; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | T := [{I to LAST} : I * 2 + N, [1] : 7, [LAST] : N * 10]
   |)
  where
    constant integer LAST = 3;
    integer N, ZN;
  end;
