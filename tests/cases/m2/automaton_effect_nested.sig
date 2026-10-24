process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := WRAP(N)
   |)
  where
    integer ZN, N;
    type MEM = external;
    automaton WRAP = ( ? integer X; ! long B; ) (| Automaton_Initial_State(S) | Automaton_Transition(S, S, ^X) | B := PEEK(X) |) where label S; end;
    process PEEK = ( ? integer X; ! long B; ) (| B := load{MEM, long}(pointer(ulong(X))) |);
  end;
