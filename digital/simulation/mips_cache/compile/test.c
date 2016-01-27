int a;

int main() {
  a = 0x30;
  *((int *)0x2000) = a;

  *((int *)0x500) = 1;

  while(1);
}