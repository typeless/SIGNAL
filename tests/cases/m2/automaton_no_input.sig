process TOGGLE =
  ( ! integer N; boolean ACTIVE; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | ACTIVE := SWITCH()
   |)
  where
    integer ZN;
    automaton SWITCH =
      ( ! boolean ACTIVE; )
      (| Automaton_Initial_State(IDLE)
       | Automaton_Transition(IDLE, BUSY, ACTIVE)
       | Automaton_Transition(BUSY, IDLE, ACTIVE)
       | ACTIVE := Automaton_IsIn(BUSY)
       |)
      where
        label IDLE, BUSY;
      end;
  end;
