process COUNTER =
  ( ! integer N; )
  pragmas
    Comment {N, ZN} "a counter"
    Target
    Note {N}
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   |)
  where
    integer ZN;
  end;
