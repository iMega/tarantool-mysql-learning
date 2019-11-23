#ifndef MY_CPU_INCLUDED
#define MY_CPU_INCLUDED
/* Copyright (c) 2013, MariaDB foundation Ab and SkySQL

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1335 USA
*/

/* instructions for specific cpu's */

/*
  Macros for adjusting thread priority (hardware multi-threading)
  The defines are the same ones used by the linux kernel
*/

#ifdef _ARCH_PWR8
/* Very low priority */
#define HMT_very_low() asm volatile("or 31,31,31")
/* Low priority */
#define HMT_low() asm volatile ("or 1,1,1")
/* Medium low priority */
#define HMT_medium_low() asm volatile ("or 6,6,6")
/* Medium priority */
#define HMT_medium() asm volatile ("or 2,2,2")
/* Medium high priority */
#define HMT_medium_high() asm volatile("or 5,5,5")
/* High priority */
#define HMT_high() asm volatile("or 3,3,3")
#else
#define HMT_very_low()
#define HMT_low()
#define HMT_medium_low()
#define HMT_medium()
#define HMT_medium_high()
#define HMT_high()
#endif

#if defined __i386__ || defined __x86_64__ || defined _WIN32
# define HAVE_PAUSE_INSTRUCTION /* added in Intel Pentium 4 */
#endif

static inline void MY_RELAX_CPU(void)
{
#ifdef _WIN32
  /*
    In the Win32 API, the x86 PAUSE instruction is executed by calling
    the YieldProcessor macro defined in WinNT.h. It is a CPU architecture-
    independent way by using YieldProcessor.
  */
  YieldProcessor();
#elif defined HAVE_PAUSE_INSTRUCTION
  /*
    According to the gcc info page, asm volatile means that the
    instruction has important side-effects and must not be removed.
    Also asm volatile may trigger a memory barrier (spilling all registers
    to memory).
  */
#ifdef __SUNPRO_CC
  asm ("pause" );
#else
  __asm__ __volatile__ ("pause");
#endif
#elif defined(_ARCH_PWR8)
  __builtin_ppc_get_timebase();
#else
  int32 var, oldval = 0;
  my_atomic_cas32_strong_explicit(&var, &oldval, 1, MY_MEMORY_ORDER_RELAXED,
                                  MY_MEMORY_ORDER_RELAXED);
#endif
}


#ifdef HAVE_PAUSE_INSTRUCTION
# ifdef __cplusplus
extern "C" {
# endif
extern unsigned my_cpu_relax_multiplier;
void my_cpu_init(void);
# ifdef __cplusplus
}
# endif
#else
# define my_cpu_relax_multiplier 200
# define my_cpu_init() /* nothing */
#endif

/*
  LF_BACKOFF should be used to improve performance on hyperthreaded CPUs. Intel
  recommends to use it in spin loops also on non-HT machines to reduce power
  consumption (see e.g http://softwarecommunity.intel.com/articles/eng/2004.htm)

  Running benchmarks for spinlocks implemented with InterlockedCompareExchange
  and YieldProcessor shows that much better performance is achieved by calling
  YieldProcessor in a loop - that is, yielding longer. On Intel boxes setting
  loop count in the range 200-300 brought best results.
*/

static inline int LF_BACKOFF(void)
{
  unsigned i= my_cpu_relax_multiplier;
  while (i--)
    MY_RELAX_CPU();
  return 1;
}

/**
  Run a delay loop while waiting for a shared resource to be released.
  @param delay originally, roughly microseconds on 100 MHz Intel Pentium
*/
static inline void ut_delay(unsigned delay)
{
  unsigned i= my_cpu_relax_multiplier / 4 * delay;
  HMT_low();
  while (i--)
    MY_RELAX_CPU();
  HMT_medium();
}

#endif