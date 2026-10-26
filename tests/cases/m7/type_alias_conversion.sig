process P =
  ( ! integer Y; )
  (| N := ZN + 1 | ZN := N $ init 0
   | W := word(N * 300)
   | Y := integer(W)
   |)
  where
    type word = ubyte;
    type word2 = word;
    integer ZN, N;
    word2 W;
  end;
