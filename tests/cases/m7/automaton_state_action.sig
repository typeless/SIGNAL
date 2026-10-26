process TOGGLE =
  ( ! integer N, OUT; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | OUT := SWITCH(^N, when N modulo 3 = 0)
   |)
  where
    integer ZN;
    automaton SWITCH =
      ( ? event TICK, PRESS; ! integer OUT; )
      (| Automaton_Initial_State(IDLE)
       | Automaton_Transition(IDLE, BUSY, PRESS)
       | Automaton_Transition(BUSY, IDLE, PRESS)
       | BUSY :: (| OUT := 1 |)
       |)
      where
        label IDLE, BUSY;
      end;
  end;
