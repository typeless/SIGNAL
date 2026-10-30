process GREET =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R1 :: NAME := read("name? " when ^N)
   | R2 :: AGE := read("age? ")
   | W1 :: write("hello ", NAME)
   | W2 :: write("next year you are ", AGE + 1)
   | REPLY := if NAME = "root" then "welcome back" else "nice to meet you"
   | W3 :: writeString(REPLY)
   | W4 :: write("mark ", if AGE > 18 then '\xE9' else 'k')
   | NAME ^= AGE
   | R1 --> R2 --> W1 --> W2 --> W3 --> W4
   |)
  where
    string NAME, REPLY;
    integer N, ZN;
    integer AGE;
    label R1, R2, W1, W2, W3, W4;
  end;
