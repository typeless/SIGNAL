process P =
  ( ! integer Y; )
  (| Y := A[BIG] |)
  where
    constant ulong BIG = 5;
    constant [3] integer A = [1,2,3];
  end;
