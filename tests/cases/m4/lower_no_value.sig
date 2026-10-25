process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := integer(color#blue)
   |)
  where
    integer ZN, N;
    type color = enum(red, green);
  end;
