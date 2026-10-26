process P =
  ( ! integer B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := (N |* 4)[1]
   |)
  where
    integer ZN, N;
  end;
