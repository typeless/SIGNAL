process TOGGLE =
  ( ! integer N, B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := SWITCH(N, when N modulo 3 = 0)
   |)
  where
    integer ZN;
    automaton SWITCH =
      ( ? integer V; event PRESS; ! integer OUT; )
      (| Automaton_Initial_State(IDLE)
       | Automaton_Transition(IDLE, BUSY, PRESS)
       | Automaton_Transition(BUSY, IDLE, PRESS)
       | OUT := V when ^BUSY
       |)
      where
        label IDLE, BUSY;
      end;
  end;
