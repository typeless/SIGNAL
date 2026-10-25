process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N[0]
   |)
  where
    integer ZN, N;
    
  end;
