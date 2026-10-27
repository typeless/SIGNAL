process P_chart =
  ( ? event Tick;
      boolean A, B;
    ! P_states P_currentState; )
  (| case P_currentState in
       {#Q}: (| P_nextState ::= (#R when a) default (#S when b) |)
       {#R}: (| P_nextState ::= #S when b |)
       {#S}: (| P_nextState ::= #Q when a |)
     end
   | P_nextState ::= defaultvalue P_currentState
   | P_currentState := P_nextState $ init #Q
   | P_currentState ^= Tick
   | a := when A
   | b := when B
   | A ^= B ^= Tick
   |)
  where
    type P_states = enum (Q, R, S);
    shared P_states P_nextState;
    event a, b;
  end;
