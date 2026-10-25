process TOP =
  ( ? integer A; ! integer B; )
  (| B := LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + LEAF(A) + MID(A)
   |)
  where
    type color = enum (red, green);
    process LEAF = ( ? integer A; ! integer B; ) (| B := A + 1 |);
    process MID = ( ? integer A; ! integer B; )
      (| red := LEAF(A)
       | C := #red
       | B := integer(C) + red
       |)
      where
        integer red;
        color C;
      end;
  end;
