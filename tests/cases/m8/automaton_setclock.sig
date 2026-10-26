process P =
  ( ! integer N, S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S := FSM(N, N modulo 3 = 0)
   |)
  where
    integer ZN;
    automaton FSM =
      ( ? integer X; boolean B; ! integer ST; )
      (| Automaton_Initial_State(A)
       | Automaton_SetClock(when B)
       | Automaton_Transition(A, C, when (X > 0))
       | Automaton_Transition(C, A, when (X > 0))
       | ST := (1 when Automaton_IsIn(A)) default (2 when Automaton_IsIn(C))
       |)
      where
        label A, C;
      end;
  end;
