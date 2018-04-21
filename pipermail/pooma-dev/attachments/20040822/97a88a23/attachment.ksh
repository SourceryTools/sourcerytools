--- pooma-bk/r2/benchmarks/Doof2d/Doof2d.h	2003-11-23 23:19:54.000000000 +0100
+++ pooma-bib/r2/benchmarks/Doof2d/Doof2d.h	2004-08-22 00:00:48.000000000 +0200
@@ -346,7 +346,7 @@
   const char* qualification() const
   {
     typedef typename Store::Engine_t Engine_t;
-    return ::qualification(a_m).c_str();
+    return ::qualification(this->a_m).c_str();
   }
 
   void run() 
@@ -367,27 +367,27 @@
       {
 	for (i = 2; i <= this->n_m - 1; i++) 
 	{
-	  a_m(i,j) = fact *
-	    (b_m(i+1,j+1) + b_m(i+1,j  ) + b_m(i+1,j-1) +
-	     b_m(i  ,j+1) + b_m(i  ,j  ) + b_m(i  ,j-1) +
-	     b_m(i-1,j+1) + b_m(i-1,j  ) + b_m(i-1,j-1));
+	  this->a_m(i,j) = fact *
+	    (this->b_m(i+1,j+1) + this->b_m(i+1,j  ) + this->b_m(i+1,j-1) +
+	     this->b_m(i  ,j+1) + this->b_m(i  ,j  ) + this->b_m(i  ,j-1) +
+	     this->b_m(i-1,j+1) + this->b_m(i-1,j  ) + this->b_m(i-1,j-1));
 	}
       }
       for (j = 2; j <= this->n_m-1; j++) 
       {
         for (i = 2; i <= this->n_m-1; i++) 
 	{
-	  b_m(i,j) = fact *
-	    (a_m(i+1,j+1) + a_m(i+1,j  ) + a_m(i+1,j-1) +
-	     a_m(i  ,j+1) + a_m(i  ,j  ) + a_m(i  ,j-1) +
-	     a_m(i-1,j+1) + a_m(i-1,j  ) + a_m(i-1,j-1));
+	  this->b_m(i,j) = fact *
+	    (this->a_m(i+1,j+1) + this->a_m(i+1,j  ) + this->a_m(i+1,j-1) +
+	     this->a_m(i  ,j+1) + this->a_m(i  ,j  ) + this->a_m(i  ,j-1) +
+	     this->a_m(i-1,j+1) + this->a_m(i-1,j  ) + this->a_m(i-1,j-1));
 	}
       }
     }
      
     // Save result for checking.
     
-    this->check_m = b_m(this->n_m / 2, this->n_m / 2);
+    this->check_m = this->b_m(this->n_m / 2, this->n_m / 2);
   }
 
   void runSetup()
@@ -398,11 +398,11 @@
     {
       for (int i = 1; i <= this->n_m; i++) 
       {
-	a_m(i,j) = 0.0;
-	b_m(i,j) = 0.0;
+	this->a_m(i,j) = 0.0;
+	this->b_m(i,j) = 0.0;
       }
     }
-    b_m(this->n_m/2,this->n_m/2) = 1000.0;
+    this->b_m(this->n_m/2,this->n_m/2) = 1000.0;
   }
 };
 
@@ -431,7 +431,7 @@
   {
     typedef typename Store::Engine_t Engine_t;
 
-    std::string qual = ::qualification(a_m);
+    std::string qual = ::qualification(this->a_m);
 
     if (guarded_m)
     {
@@ -458,31 +458,31 @@
     
     for (k = 0; k < 5; ++k)
     {
-      a_m(I,J) = fact *
-	(b_m(I+1,J+1) + b_m(I+1,J  ) + b_m(I+1,J-1) +
-	 b_m(I  ,J+1) + b_m(I  ,J  ) + b_m(I  ,J-1) +
-	 b_m(I-1,J+1) + b_m(I-1,J  ) + b_m(I-1,J-1));
-      b_m(I,J) = fact *
-	(a_m(I+1,J+1) + a_m(I+1,J  ) + a_m(I+1,J-1) +
-	 a_m(I  ,J+1) + a_m(I  ,J  ) + a_m(I  ,J-1) +
-	 a_m(I-1,J+1) + a_m(I-1,J  ) + a_m(I-1,J-1));
+      this->a_m(this->I,this->J) = fact *
+	(this->b_m(this->I+1,this->J+1) + this->b_m(this->I+1,this->J  ) + this->b_m(this->I+1,this->J-1) +
+	 this->b_m(this->I  ,this->J+1) + this->b_m(this->I  ,this->J  ) + this->b_m(this->I  ,this->J-1) +
+	 this->b_m(this->I-1,this->J+1) + this->b_m(this->I-1,this->J  ) + this->b_m(this->I-1,this->J-1));
+      this->b_m(this->I,this->J) = fact *
+	(this->a_m(this->I+1,this->J+1) + this->a_m(this->I+1,this->J  ) + this->a_m(this->I+1,this->J-1) +
+	 this->a_m(this->I  ,this->J+1) + this->a_m(this->I  ,this->J  ) + this->a_m(this->I  ,this->J-1) +
+	 this->a_m(this->I-1,this->J+1) + this->a_m(this->I-1,this->J  ) + this->a_m(this->I-1,this->J-1));
     }
 
     Pooma::blockAndEvaluate();
 
     // Save result for checking.
     
-    this->check_m = b_m(this->n_m / 2, this->n_m / 2);
+    this->check_m = this->b_m(this->n_m / 2, this->n_m / 2);
   }
 
   void runSetup()
   {
     // Run setup.
     
-    a_m = 0.0;
-    b_m = 0.0;
+    this->a_m = 0.0;
+    this->b_m = 0.0;
     Pooma::blockAndEvaluate();
-    b_m(this->n_m/2,this->n_m/2) = 1000.0;
+    this->b_m(this->n_m/2,this->n_m/2) = 1000.0;
   }
 
 private:
@@ -535,7 +535,7 @@
   const char* qualification() const
   {
     typedef typename Store::Engine_t Engine_t;
-    std::string qual = ::qualification(a_m);
+    std::string qual = ::qualification(this->a_m);
 
     if (guarded_m)
     {
@@ -551,7 +551,7 @@
   void run() 
   {
     int k;
-    Interval<2> IJ(I,J);
+    Interval<2> IJ(this->I,this->J);
 
     // Run setup.
     
@@ -561,30 +561,30 @@
     
     for (k = 0; k < 5; ++k)
     {
-      a_m(IJ) = stencil_m(b_m,IJ);
+      this->a_m(IJ) = stencil_m(this->b_m,IJ);
 
       // Note we use this form of the stencil since adding guard cells can
       // add external guard cells so the domain of a_m might be bigger than
       // we expect, in which case stencil_m(a_m) would be bigger than IJ.
 
-      b_m(IJ) = stencil_m(a_m,IJ);
+      this->b_m(IJ) = stencil_m(this->a_m,IJ);
     }
 
     Pooma::blockAndEvaluate();
 
     // Save result for checking.
     
-    this->check_m = b_m(this->n_m / 2, this->n_m / 2);
+    this->check_m = this->b_m(this->n_m / 2, this->n_m / 2);
   }
 
   void runSetup()
   {
     // Run setup.
     
-    a_m = 0.0;
-    b_m = 0.0;
+    this->a_m = 0.0;
+    this->b_m = 0.0;
     Pooma::blockAndEvaluate();
-    b_m(this->n_m/2,this->n_m/2) = 1000.0;
+    this->b_m(this->n_m/2,this->n_m/2) = 1000.0;
 
   }
 
