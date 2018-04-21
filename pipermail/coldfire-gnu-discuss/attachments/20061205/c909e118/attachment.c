     1	unsigned int inner_prod(const unsigned int *x, const unsigned int *y, int len)
     2	{
     3	unsigned int sum, t1, t2, t3;
     4	__asm__  (
     5	"asr.l #2, %3;\n"
     6	"\tbeq 1f;\n"
     7	"\tmove.l #0, %%d3;\n"
     8	"\tmove.l %%d3, %%macsr;\n"
     9	
    10	"\t0:;\n"
    11	"\tmove.l #0, %%acc0;\n"
    12	
    13	"\tmove.w (%1)+, %4;\n"
    14	"\tmove.w (%2)+, %5;\n"
    15	"\tmac.l %4, %5, %%acc0;\n"
    16	"\tmove.w (%1)+, %4;\n"
    17	"\tmove.w (%2)+, %5;\n"
    18	"\tmac.l %4, %5, %%acc0;\n"
    19	"\tmove.w (%1)+, %4;\n"
    20	"\tmove.w (%2)+, %5;\n"
    21	"\tmac.l %4, %5, %%acc0;\n"
    22	"\tmove.w (%1)+, %4;\n"
    23	"\tmove.w (%2)+, %5;\n"
    24	"\tmac.l %4, %5, %%acc0;\n"
    25	
    26	"\tmove.l %%acc0, %6;\n"
    27	"\tasr.l #6, %6;\n"
    28	
    29	"\tadd.l %6, %0;\n"
    30	
    31	"\tsub.l #1, %3;\n"
    32	"\tbne 0b;\n"
    33	
    34	"\t1:;\n"
    35	: "=d" (sum)
    36	: "a"(x), "a"(y), "d"(len), "d"(t1), "d"(t2), "d"(t3)
    37	:"cc"
    38	);
    39	return sum;
    40	}
    41	
    42	
    43	int main() {
    44		unsigned int tab1[10];
    45		unsigned int tab2[10];
    46		unsigned int r;
    47		r = inner_prod(tab1,tab2,2);
    48	}