diff -rN -uN old-work-stefan2/src/vsip/impl/fft/dft.hpp new-work-stefan2/src/vsip/impl/fft/dft.hpp
--- old-work-stefan2/src/vsip/impl/fft/dft.hpp	2006-05-09 23:31:12.000000000 -0400
+++ new-work-stefan2/src/vsip/impl/fft/dft.hpp	2006-05-09 23:31:12.000000000 -0400
@@ -189,7 +189,7 @@
       for (index_type k = 0; k < l/2 + 1; ++k)
 	sum += in[k * in_s] * sin_cos<T>(phi * k * w);
       for (index_type k = l/2 + 1; k < l; ++k)
-	sum += conj(in[(l - k) * in_s]) * sin_cos<T>(phi * (l - k) * w);
+	sum += conj(in[(l - k) * in_s]) * sin_cos<T>(phi * k * w);
       out[w * out_s] = sum.real();
     }
   }
@@ -207,7 +207,7 @@
 	  * sin_cos<T>(phi * k * w);
       for (index_type k = l/2 + 1; k < l; ++k)
 	sum += complex<T>(in.first[(l - k) * in_s], -in.second[(l - k) * in_s])
-	  * sin_cos<T>(phi * (l - k) * w);
+	  * sin_cos<T>(phi * k * w);
       out[w * out_s] = sum.real();
     }
   }

