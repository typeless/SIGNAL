process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   |)
  where
    integer ZN;
    ref Q;
  end;
