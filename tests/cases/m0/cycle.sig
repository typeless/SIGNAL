process CYCLE =
  ( ! integer A; )
  (| A := B + 1
   | B := A * 2
   |)
  where
    integer B;
  end;
