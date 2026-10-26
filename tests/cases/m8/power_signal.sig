process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N ** N
   |)
  where
    integer ZN;
  end;
