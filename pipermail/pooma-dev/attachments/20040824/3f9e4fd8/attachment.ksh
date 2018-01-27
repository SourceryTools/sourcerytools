Serial POOMA 2.4.1 Testing
Serial POOMA testing consists of running all the regression tests.

compiler	arch	pass / fail
gcc 3.3.4	ia32	<untested>
gcc 3.4		ia32	dynamic_array_test5.cpp fails b/c STL iterator problem
gcc 3.4		amd64	dynamic_array_test5.cpp fails b/c STL iterator problem
Intel 7.1	ia32	dynamic_array_test5.cpp fails b/c STL iterator problem

Parallel POOMA 2.4.1 Testing
How do we test this?

compiler	arch	parallel	pass/ fail
gcc 3.3.4	ia32	Cheetah+MPI	<untested; Oldham>
gcc 3.3.4	ia32	Cheetah+MM	<untested; Oldham>
gcc 3.4		ia32	Cheetah+MPI	<untested; Oldham>
gcc 3.4		ia32	Cheetah+MM	<untested; Oldham>
Intel 8.0	ia64	OpenMP		compiler problems for array_test5, ScalarCode

Cheetah 1.1.4 Testing
Run all Cheetah regression tests.

compiler	arch	parallel	pass/ fail
gcc 3.3.4	ia32	MPI		<untested; Oldham>
gcc 3.3.4	ia32	MM		<untested; Oldham>
gcc 3.4		ia32	MPI		<untested; Oldham>
gcc 3.4		ia32	MM		<untested; Oldham>
