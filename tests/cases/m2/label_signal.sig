process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | HERE :: X := N
   | Y := HERE
   |)
  where
    integer ZN, N;
    integer X;
    label HERE;
  end;
