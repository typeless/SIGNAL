process FARHUGE =
  ( ! long X; integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(1)
   | iterate I of T := T[?] next 0 : long(N) end
   | X := T[0]
   | Y := L15(N)
   |)
  where
    integer ZN, N;
    [1] integer I;
    [72057594037927936] long T;
    process L0 = ( ? integer A; ! integer B; ) (| B := A + 1 |);
    process L1 = ( ? integer A; ! integer B; ) (| B := L0(L0(A)) |);
    process L2 = ( ? integer A; ! integer B; ) (| B := L1(L1(A)) |);
    process L3 = ( ? integer A; ! integer B; ) (| B := L2(L2(A)) |);
    process L4 = ( ? integer A; ! integer B; ) (| B := L3(L3(A)) |);
    process L5 = ( ? integer A; ! integer B; ) (| B := L4(L4(A)) |);
    process L6 = ( ? integer A; ! integer B; ) (| B := L5(L5(A)) |);
    process L7 = ( ? integer A; ! integer B; ) (| B := L6(L6(A)) |);
    process L8 = ( ? integer A; ! integer B; ) (| B := L7(L7(A)) |);
    process L9 = ( ? integer A; ! integer B; ) (| B := L8(L8(A)) |);
    process L10 = ( ? integer A; ! integer B; ) (| B := L9(L9(A)) |);
    process L11 = ( ? integer A; ! integer B; ) (| B := L10(L10(A)) |);
    process L12 = ( ? integer A; ! integer B; ) (| B := L11(L11(A)) |);
    process L13 = ( ? integer A; ! integer B; ) (| B := L12(L12(A)) |);
    process L14 = ( ? integer A; ! integer B; ) (| B := L13(L13(A)) |);
    process L15 = ( ? integer A; ! integer B; ) (| B := L14(L14(A)) |);
  end;
