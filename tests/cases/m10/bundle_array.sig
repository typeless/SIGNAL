process BUNDLEARRAY =
  ( ? integer N; ! integer T; )
  (| M.A := [N, N, N]
   | T := M[0].A
   |)
  where
    [3] bundle (integer A;) M;
  end;
