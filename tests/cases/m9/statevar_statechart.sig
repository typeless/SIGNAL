process P07 =
  ( ? event Tick;
      boolean A, B;
    ! P_states P_currentState; )
  (| P_currentState := P_State? when Tick
   | case P_currentState in
       {#Q}: (| P_State ::= (#R when a) default (#S when b) |)
       {#R}: (| P_State ::= #S when b |)
       {#S}: (| P_State ::= #Q when a |)
     end
   | a := when A
   | b := when B
   | A ^= B ^= Tick
   |)
  where
    type P_states = enum (Q, R, S);
    statevar P_states P_State init #Q;
    event a, b;
  end;
