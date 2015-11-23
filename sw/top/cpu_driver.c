extern void cpu_flow_0(void);
extern void cpu_flow_1(void);

int main();

typedef struct cpu_flow_data
{
  void (*func)(void *argc, int argv);
  int massiv[5];
} cpu_flow_data;

volatile int request_flag_par_cpu;
cpu_flow_data cpu_data_1;

void call_cpu_par(void (*func)(void *argc, int argv), int a, int b, int c, int d, int e){

  while(request_flag_par_cpu);

  cpu_data_1.func = func;
  
  cpu_data_1.massiv[0] = a;
  cpu_data_1.massiv[1] = b;
  cpu_data_1.massiv[2] = c;
  cpu_data_1.massiv[3] = d;
  cpu_data_1.massiv[4] = e;

  request_flag_par_cpu = 1;
}

void cpu_flow_handler(cpu_flow_data *s_cpu_flow_data) {
  while(!request_flag_par_cpu);
  cpu_flow_data sec_cpu_flow_data = *s_cpu_flow_data;
  request_flag_par_cpu = 0;
  sec_cpu_flow_data.func(sec_cpu_flow_data.massiv, 5);
}

void cpu_flow_0(void) {
  request_flag_par_cpu = 0;
  main();
}

void cpu_flow_1(void) {

  while(1) {
    cpu_flow_handler(&cpu_data_1);
  }
}