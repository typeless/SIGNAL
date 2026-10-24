process SEEDED =
  ( ! integer A0, A1, A2; )
  (| I := indices(3)
   | iterate I of S := S[?] next I : S[?][I] + 1 with S := BASE[R] end
   | A0 := S[0]
   | A1 := S[1]
   | A2 := S[2]
   |)
  where
    constant [3] integer BASE = [5, 7, 9];
    constant [3] integer R = [0, 1, 2];
    [3] integer I, S;
  end;
