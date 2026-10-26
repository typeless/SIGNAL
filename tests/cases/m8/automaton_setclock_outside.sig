process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Automaton_SetClock(when (N > 2))
   |)
  where
    integer ZN;
  end;
