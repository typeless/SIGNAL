process BADTYPE =
  ( ! boolean X; )
  (| X := T and true
   | T := ZT + 1
   | ZT := T $ init 0
   |)
  where
    integer T, ZT;
  end;
