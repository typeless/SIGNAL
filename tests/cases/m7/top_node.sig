node SUM =
  ( ? integer X; ! integer S; )
  (| S := X + ZS
   | ZS := S $ init 0
   |)
  where
    integer ZS;
  end;
