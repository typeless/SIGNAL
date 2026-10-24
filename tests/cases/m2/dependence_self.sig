process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N
   | K --> K
   |)
  where
    integer ZN, K;
  end;
