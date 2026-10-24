process P =
  ( ! integer Y; )
  (| Y := load(1) |)
  where
    function load = ( ? integer A; ! integer B; ) (| B := A |);
  end;
