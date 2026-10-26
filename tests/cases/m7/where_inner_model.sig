process P =
  ( ! integer N; )
  (| (| N := INNER(1) |)
     where
       process INNER =
         ( ? integer X; ! integer C; )
         (| C := X |);
     end
   |);
