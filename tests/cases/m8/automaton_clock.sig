process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := FSM(N, N modulo 3 = 0)
   |)
  where
    integer ZN;
    automaton FSM =
      ( ? integer X; boolean B; ! integer Y; )
      (| Automaton_Initial_State(A)
       | Automaton_SetClock(when B)
       | Automaton_Transition(A, A, when (X > 0))
       | H := Automaton_Clock()
       | Y := X when H
       |)
      where
        event H;
        label A;
      end;
  end;
