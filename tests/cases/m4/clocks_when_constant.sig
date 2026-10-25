process WC =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N when true
   |)
  where
    integer ZN, N;
  end;
