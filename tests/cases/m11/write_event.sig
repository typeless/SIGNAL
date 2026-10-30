process WRITEEVENT =
  ( ? event E; ! integer N; )
  (| N := 1 when E
   | write("e", E)
   |)
  where
  end;
