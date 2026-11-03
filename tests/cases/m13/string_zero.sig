process STRINGZERO =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | W :: write("[", "a\0b\000" when N < 2)
   |)
  where
    integer ZN;
    label W;
  end;
