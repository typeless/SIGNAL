process TOGGLE =
  ( ! integer N, OUT; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | OUT := SWITCH(^N, when N modulo 3 = 0, when N > 4)
   |)
  where
    integer ZN;
    automaton SWITCH =
      ( ? event TICK, PRESS, LATE; ! integer OUT; )
      (| Automaton_Initial_State(IDLE)
       | on LATE :: Automaton_Transition(IDLE, BUSY, PRESS)
       | Automaton_Transition(BUSY, IDLE, PRESS)
       | IDLE :: (| IDLE_OUT := 0 |)
       | OUT := (1 when Automaton_IsIn(BUSY)) default IDLE_OUT
       |)
      where
        label IDLE, BUSY;
        integer IDLE_OUT;
      end;
  end;
