process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | L :: X := N
   | Y := L
   |)
  where
    integer ZN, X;
    label L;
  end;
