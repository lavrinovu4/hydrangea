#include "cpu_driver.h"

#define MAX_CYCLE 3

#define INIT 0
#define SHIFT 1

// unsigned int LED __attribute__((__at(0x2000)));
#define LED *((int *)0x2000)

static inline
void end_simulation(void) {
    *((int *) 0x500) = 1;
}


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

#ifdef FOR_SIMULATION

  int i;
  for(i = 0; i < MAX_CYCLE; i++) {

#else

  for(;;) {

#endif

    register int k = 0x100;
    while(--k);
    shift(0);
    call_cpu_par(&func_par, SHIFT, 1, 0, 0, 0);
  }

#ifdef FOR_SIMULATION
  end_simulation();

  return 0;
#endif

}
