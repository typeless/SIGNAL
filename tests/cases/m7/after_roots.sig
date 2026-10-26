process P =
  ( ? integer A, B; ! integer N; )
  (| H1 := when (A > 0)
   | H2 := when (B > 0)
   | N := H1 after H2
   |)
  where
    event H1, H2;
  end;
