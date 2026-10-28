process WINDOWSCALARINIT =
  ( ! integer N; [2] integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N window 2 init 9
   |)
  where
    integer ZN;
  end;
