process DELAYINITLISTSIGNAL =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N $ 2 init [5, N]
   |)
  where
    integer ZN, N;
  end;
