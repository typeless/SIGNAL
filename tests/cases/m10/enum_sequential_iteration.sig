process ENUMSEQUENTIALITERATION =
  ( ? event TICK; ! [3, 2] integer M; [6] integer V; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | M := [{I to 2, J to 1} : I * 10 + J, {K in 1 to 2} : [K, 1] : N * 100 + K]
   | V := [{I in -2 to 3 step 1} : [I + 2] : I * N, {I in 0 to 5 step 2} : [I] : 100 + I]
   |)
  where
    integer N, ZN;
  end;
