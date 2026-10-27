process P_chart =
  ( ? event Tick;
      boolean A, B, I, J, M, NN;
    ! P_states P_currentState;
      Q1_states Q1_currentState;
      Q2_states Q2_currentState; )
  (| (| P_currentState := P_State? when Tick
      | case P_currentState in
          {#Q}: (| P_State ::= (#R when a) default (#S when b) |)
          {#R}: (| P_State ::= #S when b |)
          {#S}: (| P_State ::= #Q when a
                 | start_Q_chart := a
                 |)
        end
      |)
   | clk_Q_chart := when (P_currentState = #Q)
   | (| Q1_currentState := Q1_State? when clk_Q_chart
      | Q1_State ::= #U when start_Q_chart
      | case Q1_currentState in
          {#U}: (| Q1_State ::= #V when i |)
          {#V}: (| Q1_State ::= #U when j |)
        end
      |)
   | (| Q2_currentState := Q2_State? when clk_Q_chart
      | Q2_State ::= #X when start_Q_chart
      | case Q2_currentState in
          {#X}: (| Q2_State ::= #Y when m |)
          {#Y}: (| Q2_State ::= #Z when n |)
          {#Z}: (| Q2_State ::= #X when j |)
        end
      |)
   | a := when A | b := when B | i := when I | j := when J | m := when M | n := when NN
   | A ^= B ^= I ^= J ^= M ^= NN ^= Tick
   |)
  where
    type P_states = enum (Q, R, S);
    type Q1_states = enum (U, V);
    type Q2_states = enum (X, Y, Z);
    statevar P_states P_State init #Q;
    statevar Q1_states Q1_State init #U;
    statevar Q2_states Q2_State init #X;
    event clk_Q_chart, start_Q_chart;
    event a, b, i, j, m, n;
  end;
