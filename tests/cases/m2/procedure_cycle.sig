process FEEDBACK =
  ( ! integer A; )
  (| A := HOLD(A + 1) |)
  where
    procedure HOLD =
      ( ? integer X; ! integer Y; )
      (| Y := X $ init 0 |);
  end;
