process STRINGCONVERT =
  ( ? integer N; ! boolean B; )
  (| S := string(N)
   | B := S = ""
   |)
  where
    string S;
  end;
