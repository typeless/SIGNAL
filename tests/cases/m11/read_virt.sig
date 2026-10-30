process READVIRT =
  ( ? event START;
    ! integer N; )
  pragmas
    Boot {START}
  end pragmas
  (| N := 1 when START
   | S := read("") when START
   |)
  where
    string S;
  end;
