process STRINGTAB =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | writeString("a	b")
   |)
  where
    integer ZN;
  end;
