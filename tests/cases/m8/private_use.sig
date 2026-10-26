module A =
  private use B;
  constant integer PUB = 8;
end;
module B =
  constant integer PB = 1;
end;
process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   |)
  where
    use A;
    integer ZN;
  end;
