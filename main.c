#include <stdint.h>

#define APB_CLOCK 8000000   // Peripherial clock. This is the default value

/* Helper macros */
#define U8_BIT(x) ((uint8_t) (1 << x))
#define U16_BIT(x) ((uint16_t) (1 << x))
#define U32_BIT(x) ((uint32_t) (1 << x))

#define DIV_4(x) (x >> 2)
#define MUL_4(x) (x << 2)

/* RCC stuff */
typedef struct {
  volatile uint32_t R32_RCC_CTRL;
  volatile uint32_t R32_RCC_CFGR0;
  volatile uint32_t R32_RCC_INTR;
  volatile uint32_t R32_RCC_APB2PRSTR;
  volatile uint32_t R32_RCC_APB1PRSTR;
  volatile uint32_t R32_RCC_AHBPCENR;
  volatile uint32_t R32_RCC_APB2PCENR;
  volatile uint32_t R32_RCC_APB1PCENR;
  volatile uint32_t R32_RCC_BDCTLR;
  volatile uint32_t R32_RCC_RSTSCKR;
  volatile uint32_t R32_RCC_AHBRSTR;
  volatile uint32_t R32_RCC_CFGR2;
} RCC_Regfile;

#define RCC_BASE ((uint32_t)0x40021000)
#define RCC_APB2PCENR_IOPAEN U32_BIT(2)
#define RCC_APB2PCENR_USART1EN U32_BIT(14)
#define RCC ((RCC_Regfile *) RCC_BASE)

/* GPIO stuff */
typedef struct {
  volatile uint32_t R32_GPIO_CFGLR;
  volatile uint32_t R32_GPIO_CFGHR;
  volatile uint32_t R32_GPIO_INDR;
  volatile uint32_t R32_GPIO_OUTDR;
  volatile uint32_t R32_GPIO_BSHR;
  volatile uint32_t R32_GPIO_BCR;
  volatile uint32_t R32_GPIO_LCKR;
} GPIO_Regfile;

#define GPIO_PUSH_PULL_ALTERNATE_OUTPUT 0b1001
#define GPIO_PULL_UP_INPUT 0b0001

#define GPIOA_BASE ((uint32_t)0x40010800)
#define GPIOA ((GPIO_Regfile *) GPIOA_BASE)

/* TODO make this function more generic and more compact */
void gpioa_port_config(uint8_t port, uint8_t cfg)
{
  uint8_t shift = 0;
  if (port < 8) {
    shift = port << 2;
    GPIOA->R32_GPIO_CFGLR &= ~(0xf << shift);
    GPIOA->R32_GPIO_CFGLR |= (0xf & cfg);
  }

  else {
    shift = (port - 8) << 2;
    GPIOA->R32_GPIO_CFGHR &= ~(0xf << shift);
    GPIOA->R32_GPIO_CFGHR |= (0xf & cfg) << shift;
  }
}

/* USART stuff */
typedef struct {
  volatile uint32_t R32_USART_STATR;
  volatile uint32_t R32_USART_DATAR;
  volatile uint32_t R32_USART_BRR;
  volatile uint32_t R32_USART_CTRL1;
  volatile uint32_t R32_USART_CTRL2;
  volatile uint32_t R32_USART_CTRL3;
  volatile uint32_t R32_USART_GPR;
} USART_Regfile;

#define USART_STATR_TC U32_BIT(6)
#define USART_STATR_TXE U32_BIT(7)
#define USART_CTRL1_TE U32_BIT(3)
#define USART_CTRL1_UE U32_BIT(13)

#define USART1_BASE ((uint32_t)0x40013800)
#define USART1 ((USART_Regfile *) USART1_BASE)

uint16_t calculate_brr(uint32_t apb_clock, uint32_t uart_baud_rate)
{
  uint16_t over8div = 4;
  uint16_t integer_divider = (25 * (apb_clock)) / ((over8div) * (uart_baud_rate));
  uint16_t fractional_divider = integer_divider % 100;

  return ((((integer_divider) / 100) << 4) | (((((fractional_divider) * ((over8div)*2)) + 50)/100)&7));
}

void enable_uart(void)
{
  RCC->R32_RCC_APB2PCENR |= RCC_APB2PCENR_IOPAEN;
  RCC->R32_RCC_APB2PCENR |= RCC_APB2PCENR_USART1EN;
  
  gpioa_port_config(10, GPIO_PULL_UP_INPUT);
  gpioa_port_config(9, GPIO_PUSH_PULL_ALTERNATE_OUTPUT);

  USART1->R32_USART_CTRL1 = USART_CTRL1_TE;
  USART1->R32_USART_CTRL2 = 0;
  USART1->R32_USART_CTRL3 = 0;
  USART1->R32_USART_BRR = calculate_brr(APB_CLOCK, 9600);

  USART1->R32_USART_CTRL1 |= USART_CTRL1_UE;
}

void uart_putc(char c)
{
  while (!(USART1->R32_USART_STATR & USART_STATR_TC))
    ;

  USART1->R32_USART_DATAR = c;
}

void uart_puts(const char *str)
{
  while (*str) {
    uart_putc(*str);
    str++;
  }
}

void _irq_trap(void) __attribute__((interrupt));
void _irq_trap(void)
{
  return;
}

int main()
{
  RCC->R32_RCC_APB2PCENR |= RCC_APB2PCENR_IOPAEN;
  gpioa_port_config(15, 0b0001);
  GPIOA->R32_GPIO_OUTDR |= 0b1 << 15;

  enable_uart();
  uart_puts("Hello World");
}    
