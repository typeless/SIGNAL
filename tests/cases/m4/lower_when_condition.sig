process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N when N
   |)
  where
    integer ZN, N;
    
  end;
