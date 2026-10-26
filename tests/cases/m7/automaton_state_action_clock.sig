process LAMPS =
  ( ! integer N, LIT_TICKS; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | LIT_TICKS := LAMP(N modulo 3 = 0, N modulo 2 = 0)
   |)
  where
    integer ZN;
    automaton LAMP =
      ( ? boolean PRESS, HOLD; ! integer LIT_TICKS; )
      (| Automaton_Initial_State(DARK)
       | Automaton_Transition(DARK, LIT, when PRESS)
       | Automaton_Transition(DARK, DIM, when HOLD)
       | Automaton_Transition(LIT, DARK, when PRESS)
       | Automaton_Transition(DIM, DARK, when HOLD)
       | LIT :: (| LIT_TICKS := Z + 1 | Z := LIT_TICKS $ init 0 |)
       |)
      where
        label DARK, LIT, DIM;
        integer Z;
      end;
  end;
