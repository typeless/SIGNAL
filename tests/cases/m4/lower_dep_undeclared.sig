process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N | Q --> Y
   |)
  where
    integer ZN, N;
    
  end;
