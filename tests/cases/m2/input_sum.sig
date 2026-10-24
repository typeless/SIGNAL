process ACC =
  ( ? integer X; ! integer S; )
  (| S := ZS + X
   | ZS := S $ init 0
   |)
  where
    integer ZS;
  end;
