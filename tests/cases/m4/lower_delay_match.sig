process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N $ init true
   |)
  where
    integer ZN, N;
    
  end;
