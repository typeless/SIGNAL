module A =
  private constant integer RED = 7;
  process GETS = ( ? integer X; ! integer Y; ) (| Y := X + RED |);
end;
process P =
  ( ! integer N, W; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Z := C#GREEN when N = 2 default C#RED
   | Z ^= N
   | W := integer(Z)
   |)
  where
    integer ZN;
    type C = enum (RED, GREEN);
    C Z;
  end;
