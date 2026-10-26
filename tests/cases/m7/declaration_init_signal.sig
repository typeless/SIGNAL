process COUNTER =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $
   |)
  where
    integer ZN init N;
  end;
