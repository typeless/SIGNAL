process TOP =
  ( ? integer A; ! integer B; )
  (| B := LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + MID(A) + Z
   | W :: Z := 5
   |)
  where
    type color = enum (red, green);
    label W;
    integer Z;
    process LEAF = ( ? integer A; ! integer B; ) (| B := A + 1 |);
    process MID = ( ? integer A; ! integer B; )
      (| red := A
       | B := red + 1
       | red --> B
       |)
      where
        integer red;
      end;
  end;
