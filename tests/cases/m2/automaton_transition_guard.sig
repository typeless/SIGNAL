process TOGGLE =
  ( ! integer N; boolean ACTIVE; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | ACTIVE := SWITCH(^N, when N modulo 3 = 0, when N > 4)
   |)
  where
    integer ZN;
    automaton SWITCH =
      ( ? event TICK, PRESS, LATE; ! boolean ACTIVE; )
      (| Automaton_Initial_State(IDLE)
       | on LATE :: Automaton_Transition(IDLE, BUSY, PRESS)
       | Automaton_Transition(BUSY, IDLE, PRESS)
       | ACTIVE := Automaton_IsIn(BUSY)
       |)
      where
        label IDLE, BUSY;
      end;
  end;
