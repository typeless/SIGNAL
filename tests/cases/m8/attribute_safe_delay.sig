process P =
  ( ! integer N; ) safe
  (| N := ZN + 1
   | ZN := N $ init 0
   |)
  where
    integer ZN;
  end;
