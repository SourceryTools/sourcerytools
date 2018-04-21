# 1 "gmem.c"
# 1 "/home/garrett/project/svn/tsinfra/share/fc2-base/rpm-sources/m68k/BUILD/glib-2.4.0/glib//"
# 1 "<built-in>"
# 1 "<command line>"
# 1 "gmem.c"
# 31 "gmem.c"

# 1 "glib.h" 1
# 30 "glib.h"
# 1 "../glib/galloca.h" 1
# 30 "../glib/galloca.h"
# 1 "../glib/gtypes.h" 1
# 30 "../glib/gtypes.h"
# 41 "../glib/gtypes.h"

typedef char gchar;
typedef unsigned long gulong;
typedef unsigned int guint;
typedef double gdouble;

# 31 "../glib/galloca.h" 2
# 31 "glib.h" 2
# 1 "../glib/gcache.h" 1
# 30 "../glib/gcache.h"
# 1 "../glib/glist.h" 1
# 30 "../glib/glist.h"
# 1 "../glib/gmem.h" 1
# 72 "../glib/gmem.h"

void g_mem_profile (void);

# 31 "../glib/glist.h" 2
# 31 "../glib/gcache.h" 2
# 36 "glib.h" 2
# 1 "../glib/gmessages.h" 1
# 178 "../glib/gmessages.h" 3

void g_print (const gchar *format,
                                         ...) __attribute__((__format__ (__printf__, 1, 2)));
# 345 "../glib/gmessages.h" 3
# 52 "glib.h" 2
# 38 "gmem.c" 2
# 276 "gmem.c"

static guint *profile_data = ((void *)0);

# 297 "gmem.c"

void
g_mem_profile (void)
{
  guint local_data[(4096 + 1) * 8 * sizeof (profile_data[0])];
  gulong local_mc_allocs;
  gulong local_mc_frees;

  g_print ("MemChunk bytes: (%.2f%%)",
	 ((gdouble) local_mc_frees) / local_mc_allocs * 100.0 );
}
