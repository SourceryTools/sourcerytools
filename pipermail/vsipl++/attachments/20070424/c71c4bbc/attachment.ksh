Ideas on overlaping distributions

Use cases
---------

1. STAP

  Start with tensor of processed radar data.
  Compute weights based on solving linear system consisting of neighborhood
  around pixel

  Distributed processing requires overlap, potentially wrap-around
  to deal with circular frequencies.

2. Detection.  Image processing

  Start with input image
   - compute multiple filters on input image
   - threshold filter results to find detections
   - processing is "out of place".

  Distributed processing requires overlap.

3. Physics.

TODO: processing example that requires guard cells.



Strawman proposal
-----------------
 - Add overlap to Block_dist (default value is 0).
   (possibly have separate left and right overlap).

 - Extend maps to have read-domain and write-domain.

   The global write domain is the subset of global view owned by the
   processor.  It is the same as the current "global domain".

   The global read domain is the write domain, plus an additional
   cells necessary to meet overlap requirements.

   A processor's overlap values are those in its read domain, but not
   in its write domain.

 - In view-level computations (i.e. A = B*C), a processor is
   responsible for computing values in its write domain of the LHS.
   Values on the RHS fall into three categories:
    - in the processor's write domain -- use local value
    - in the processor's read domain -- use local value
    - not in the processor's read/write domain -- communication necessary
      from remote processor that owns value (i.e. in remote processor's
      write domain).

   When read domain == write domain, this is owner computes.
   
   Example (out of place processing):

	np = num_processors();
	nr = sqrt(np); nc = np/nr;

	// Map into checkerboard, with overlap of 1 pixel.
	Map<...> map_overlap(Block_dist(nr, 1), Block_dist(nc, 1));
	// Map into checkerboard, with no overlap.
	Map<...> map(Block_dist(nr, 0), Block_dist(nc, 0));

	// Note that map and map_overlap have the same write domains.

	Matrix<> A_in (map_overlap);
	Matrix<> A_out(map);
	Matrix<> B_in (map_overlap);
	Matrix<> B_out(map);

	A_in = ... initialize A

	// perform operation that requires the overlap.
	// A_out and A_in have the same write domain.
	// A_in's read domain has one extra pixel of overlap than the
	//        write domain.
	// Hence, this operation is local.  It does not reqire communication.
	A_out = convolve(A_in, 3x3 kernel);

	// Since A_out has no overlap, but B_in does, edge cells are
	// transferred between processors.

	B_in = A_out;


   Example (in place processing):

	Matrix<> A(map_overlap);
	Matrix<> B(map_overlap);

	A = ... initialize A

	// convolve operation breaks down into two steps:
	// 1) each processor computes values for its local write domain
	// 2) processors send edge values to other processor's to update
	//    remote read domains.
	A = convolve(A, 3x3 kernel);

	// perform operation that requires the overlap.
	// A_out and A_in have the same write domain.
	// A_in's read domain has one extra pixel of overlap than the
	//        write domain.
	// Hence, this operation is local.  It does not reqire communication.
	A_out = convolve(A_in, 3x3 kernel);

	// Since B and A have the same map and overlap, no communication
	// is necessary.  A's read domain values are transferred to B's.
	B = A;

 - Global element-level computations (using get/put on global view)
   work as expected:

    - view.get(idx) is effectively a broadcast from the owner of the
      value to the other processors.  The owner may skip broadcasting
      to processors who have the value in their read domains if that
      improves performance.

    - view.put(idx, value) is executed on processors that have the
      value in their write or read domains.  No communication is
      necessary.

      An alternative is to follow strict owner computes: have the
      processor that owns the value "compute" it, then broadcast to
      other processors that have the value in their read domains.
      However, VSIPL++ data-parallel semantics require that 'value'
      be the same on all processors, so the broadcast can be skipped.

   In short, manipulating distributed views with overlap using get/put
   is expensive, but no more so than distributed views without
   overlap.

 - Local operations (either view level operaions on local view,
   or get/put element operations on the local view) require special
   handling.

   Operations on the local view do not require communication.  After
   a operation modifies the local view, the overlap values become
   stale.

   Example:

	Matrix<> A(map_overlap);

	// Set A to all 1's.  Overlap values also set to 1's.
	A = 1;

	// Set A to all 0's, via local subview:
	A.local() = 0's

	// Now overlap values are stale.  They have value 1, but should
	// be 0.
	
   We could require that the local subview know it is part of a
   distributed view with overlap.  However, that would be expensive
   and would require one-side communications (there is no coordination
   between the modifications to local views).  Moreover, it would be
   inefficient.  The local view would not know the extent of the local
   processing region, and would not be able to bundle changes
   together.

   What is needed is an 'update()' function that signals local changes
   to a view have been made and the overlap values can be updated.

   In the above example

	Matrix<> A(map_overlap);

	// Set A to all 1's.  Overlap values also set to 1's.
	A = 1;

	// Set A to all 0's, via local subview:
	A.local() = 0's

	// global A has stale overlap values.  Using it at this point
	// would be undefined.

	...

	// Once all local changes are made, A's overlap values are be
	// updated.

	update(A);

	// global A is valid.


 - Guard cells

   First, let's start with an example.  We'll perform two successive
   3x3 filters on an image without communication.  This requires an
   overlap of 2.

   Example:

	// Map into checkerboard, with overlap of 1 pixel.
	Map<...> map_overlap_2(Block_dist(nr, 2), Block_dist(nc, 2));

	Matrix<> A(map_overlap_2);

	A = ... initialize ...;

	// All of A's overlap cells are valid

	// Step 1, compute first 3x3 filter.
	//
	// However, instead of computing new values for the write domain
	// and then exchanging edge values to update neighbor's overlap,
	// we want to use the extra large overlap to compute new values
	// for both the write domain, *and* part of the read domain
	// (enough so that the second filter doesn't require communication).

	A = convolve(A, 3x3 filter 1)

	// At this point, some of A's overlap values are stale.

	// Step 2, compute second 3x3 filter
	A = convolve(A, 3x3 filter 2)

	// After step 2, we want to refresh the overlap cells.  In our
	// above examples this would have happend automatically,

   Questions:
    - How does the library distinguish between an expression where
      overlap update is desired (Step 2 in above example, plus all
      earlier examples) and it is not (Step 1).

    - How does the library know when to update the guard cells (step 1)
      vs not to (step 2).  If more than two levels of guard cells are
      present, how does the library know the current step.

    - Does keeping track of overlap cell validity add significant
      overhead?

   One idea: allow user to indicate when they're expecting guard
   cell behavior.  To indicate that a guard cell should be performed,
   computing 'border' additional pixels around view's write domain:

	extend(view, border)

   The example above becomes:

	Matrix<> A(map_overlap_2);

	A = ... initialize ...;

	extend(A, 1) = convolve(A, 3x3 filter 1)
	extend(A, 0) = convolve(A, 3x3 filter 2)
	update(A)

   Or even:

	Matrix<> A(map_overlap_2);

	A = ... initialize ...;

	extend(A, 1) = convolve(A, 3x3 filter 1)
	A            = convolve(A, 3x3 filter 2)
