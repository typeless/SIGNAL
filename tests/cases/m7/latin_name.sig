process P =
  ( ! integer Élan, Èlan; )
  (| Élan := ZÉ + 1
   | ZÉ := Élan $ init 0
   | Èlan := Élan * 2
   |)
  where
    integer ZÉ;
  end;
