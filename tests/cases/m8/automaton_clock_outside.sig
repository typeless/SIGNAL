process P =
  ( ! integer N; event H; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | H := Automaton_Clock()
   |)
  where
    integer ZN;
  end;
