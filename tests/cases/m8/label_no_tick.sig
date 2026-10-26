process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | H := ^L
   | Y := N when H
   |)
  where
    integer ZN;
    event H;
    label L;
  end;
