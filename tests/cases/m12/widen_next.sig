process WIDENNEXT =
  ( ? real X; integer I;
    ! [2] dreal T; )
  (| T := W next I : X
   | X ^= I
   |)
  where
    constant [2] dreal W = [1.5d0, 2.5d0];
  end;
