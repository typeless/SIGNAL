process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | L :: K := N
   | L --> L
   |)
  where
    integer ZN, K;
    label L;
  end;
