process STRINGVALUECELL =
  ( ? integer N; ! integer K; )
  (| K := N
   | C := N > 1
   | Q := ("abc" when C) cell C init "none"
   | W :: writeString(Q when ^N)
   |)
  where
    string Q; boolean C; label W;
  end;
