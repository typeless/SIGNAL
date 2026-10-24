process TOGGLE =
  ( ! integer N; boolean ACTIVE; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | ACTIVE := SWITCH(^N, when N modulo 3 = 0)
   |)
  where
    integer ZN;
    automaton SWITCH =
      ( ? event TICK, PRESS; ! boolean ACTIVE; )
      (| Automaton_Initial_State(IDLE)
       | L :: Automaton_Transition(IDLE, BUSY, PRESS)
       | Automaton_Transition(BUSY, IDLE, PRESS)
       | ACTIVE := Automaton_IsIn(BUSY)
       | L --> ACTIVE
       |)
      where
        label IDLE, BUSY, L;
      end;
  end;
