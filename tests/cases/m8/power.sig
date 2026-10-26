process P =
  ( ! integer N, Y, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N ** 3
   | Z := (N - 1) ** 2 + 1
   |)
  where
    integer ZN;
  end;
