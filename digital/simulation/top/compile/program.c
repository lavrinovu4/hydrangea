#include "cpu_driver.h"

#define INIT 0
#define SHIFT 1

// unsigned int LED __attribute__((__at(0x2000)));
#define LED *((int *)0x2000)

void shift(int hight_low);

void func_par(void *argc, int argv) {
  int comm = *((int *)argc);

  if(comm == INIT)
    LED |= *((int *) argc + 1) << 8;
  else if(comm == SHIFT)
    shift(*((int *)argc));
}

//hight_low = 1 // hight
void shift(int hight_low) {
  unsigned int work;

  if(hight_low)
    work = LED >> 8;
  else
    work = LED & 0xff;

  work = work >> 1 | ((work & 1) << 7);


  if(hight_low){
    LED &= 0xff;
    LED |= work << 8;
  } else {
    LED &= 0xff00;
    LED |= work;
  }

}

int main() {
  LED |= 3;
  call_cpu_par(&func_par, INIT, 0x50, 0, 0, 0);

  while(1) {
    register int i = 0x100000;
    while(i--);
    shift(0);
    call_cpu_par(&func_par, SHIFT, 1, 0, 0, 0);
    *((int *) 500) = 1;
  }
}