process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Q := N | Y := N
   |)
  where
    integer ZN, N;
    
  end;
