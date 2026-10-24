process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := PEEK(N)
   |)
  where
    integer ZN, N;
    type MEM = external;
    automaton PEEK = ( ? integer X; ! long B; ) (| Automaton_Initial_State(S) | Automaton_Transition(S, S, ^X) | B := load{MEM, long}(pointer(ulong(X))) |) where label S; end;
  end;
