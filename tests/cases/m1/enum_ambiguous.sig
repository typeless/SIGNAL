process AMBIG =
  ( ! integer K; )
  (| C := #orange
   | K := integer(C)
   |)
  where
    type color = enum (yellow, orange);
    type fruit = enum (apple, orange);
    color C;
  end;
