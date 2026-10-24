process LAMPS =
  ( ! integer N, STATE; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | STATE := LAMP(N modulo 3 = 0, N modulo 2 = 0)
   |)
  where
    integer ZN;
    automaton LAMP =
      ( ? boolean PRESS, HOLD; ! integer STATE; )
      (| Automaton_Initial_State(DARK)
       | Automaton_Transition(DARK, LIT, when PRESS)
       | Automaton_Transition(DARK, DIM, when HOLD)
       | Automaton_Transition(LIT, DARK, when PRESS)
       | Automaton_Transition(DIM, DARK, when HOLD)
       | STATE := (1 when Automaton_IsIn(LIT)) default (2 when Automaton_IsIn(DIM)) default 0
       | STATE ^= PRESS
       |)
      where
        label DARK, LIT, DIM;
      end;
  end;
