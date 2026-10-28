process EXTPART =
  ( ? [3] integer A;
    ! [3] integer W; )
  (| V ::= A + 1
   | W := V
   |)
  where
    [3] integer V;
  end;
