process P =
  ( ! integer A; )
  (| N := ZN + 1 | ZN := N $ init 0
   | I := indices(6)
   | iterate I of X := X[?] next I : N end
   | A := X[0]
   |)
  where integer ZN, N; [4] integer X; [6] integer I; end;
