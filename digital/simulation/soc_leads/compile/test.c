int a;
int b;

int main() { 
  a = 0x30;
  b = a;
  *((int *)0x2000) = a;
    
  while(1);
}