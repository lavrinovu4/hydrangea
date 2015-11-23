#ifndef _CPU_DRIVER_
#define _CPU_DRIVER_

void call_cpu_par(void (*func)(void *argc, int argv), int a, int b, int c, int d, int e);

#endif