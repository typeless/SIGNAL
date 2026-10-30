process STRINGCONSTANT =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A :: write(G, C when ^N)
   | B :: writeString(E when ^N)
   | A --> B
   |)
  where
    integer ZN;
    constant string G = "hi ";
    constant char C = '\xE9';
    constant string E = "";
    label A, B;
  end;
