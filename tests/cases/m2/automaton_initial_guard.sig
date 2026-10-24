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
      (| on PRESS :: Automaton_Initial_State(IDLE)
       | Automaton_Transition(IDLE, BUSY, PRESS)
       | ACTIVE := Automaton_IsIn(BUSY)
       |)
      where
        label IDLE, BUSY;
      end;
  end;
