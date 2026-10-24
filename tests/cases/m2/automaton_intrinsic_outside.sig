process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N
   | Automaton_Initial_State(HERE)
   |)
  where
    integer ZN, N;
    label HERE;
  end;
