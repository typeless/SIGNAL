process MISMATCH =
  ( ! boolean B; )
  (| B := color#yellow = fruit#apple
   |)
  where
    type color = enum (yellow, orange);
    type fruit = enum (apple, orange);
  end;
