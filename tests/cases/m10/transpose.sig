process TRANSPOSE =
  ( ? [2, 3] short M;
    ! [3, 2] short T; [2, 3] short R; )
  (| T := tr M
   | R := tr T
   |);
