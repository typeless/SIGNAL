process READPROMPT =
  ( ? integer N; ! integer K; )
  (| K := N
   | R :: S := read("name? ")
   | W :: write("hello ", S)
   | R --> W
   | S ^= N
   |)
  where
    string S;
    label R, W;
  end;
