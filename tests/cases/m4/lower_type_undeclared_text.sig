process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := integer(load{NOPE, integer}(pointer(ulong(N))))
   |)
  where
    integer ZN, N;
    
  end;
