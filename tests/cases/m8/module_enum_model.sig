module A =
  process RED = ( ? integer X; ! integer Y; ) (| Y := X |);
end;
process P =
  ( ! integer N, W; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Z := C#RED when N = 2 default C#GREEN
   | Z ^= N
   | W := integer(Z)
   |)
  where
    integer ZN;
    type C = enum (RED, GREEN);
    C Z;
  end;
