process STRINGFIELD =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   |)
  where
    integer ZN;
    type T = struct (integer A; string B;);
  end;
