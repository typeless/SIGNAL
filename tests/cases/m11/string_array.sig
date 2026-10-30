process STRINGARRAY =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   |)
  where
    integer ZN;
    [2] string S;
  end;
