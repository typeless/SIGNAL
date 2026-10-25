process TI =
  ( ! integer Y; )
  (| Y := INNER() |)
  where
    process INNER =
      ( ! integer O; )
      (| T := ZT + 1
       | ZT := T $ init 0
       | C := T > 2
       | D := T > 4
       | O := T when C
       | O ^= T when D
       |)
      where integer T, ZT; boolean C, D; end;
  end;
