process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N
   |)
  where
    integer ZN, N;
    constant integer A = if true then 1 else 2;
  end;
