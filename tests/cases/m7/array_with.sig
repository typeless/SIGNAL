process P =
  ( ! integer S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | array K to 3 of (| R := R[?] + K * N |) with R := 0 end
   | S := R
   |)
  where
    constant integer M = 3;
    integer ZN, N, R;
  end;
