process P =
  ( ! integer N, S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S := FSM(N)
   |)
  where
    integer ZN;
    automaton FSM =
      ( ? integer X; ! integer ST; )
      (| Automaton_Initial_State(A)
       | Automaton_Transition(A, B, when (X modulo 2 = 0 and Automaton_IsIn(A)))
       | Automaton_Transition(B, A, when (X modulo 3 = 0))
       | ST := (1 when Automaton_IsIn(A)) default 2
       | ST ^= X
       |)
      where
        label A, B;
      end;
  end;
