process P =
  ( ? event T; ! integer K; )
  (| K := A(T) |)
  where
    automaton A =
      ( ? event T; ! integer K; )
      (| Automaton_Initial_State(S)
       | Automaton_Transition(S, Q, T)
       | Automaton_Transition(Q, S, T)
       | S :: (| K := ZK + 1 | ZK := K $ init 0 |)
       |)
      where
        label S, Q;
        integer ZK;
      end;
  end;
