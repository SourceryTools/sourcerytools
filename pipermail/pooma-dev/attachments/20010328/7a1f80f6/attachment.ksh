I've been looking at the field code in src/NewField
this week to fix some issues with ScalarCode.  While
it's fresh in my mind I thought I'd summarize and post
some of the known bugs/issues/desired features that
exist with the NewField source:

1) Parallelism doesn't exist yet for new field since
NewField came along after the RemoteEngine.  Primarily
this means implementing EngineView for NewField, and
some testing.

2) We need to think about how to support some operations
on replicated fields, like multiplying by non-replicated
fields.  ScalarCode operations on replicated fields need
to be worked out.  (It's probably as simple as adding
a loop over the sub-fields, but we'd need to flag the
non-replicated fields so you don't index them.)

3) Stencils.  Currently Divergence is implemented.
Probably Blanca will write their own versions, but
we need to make sure that we can support the required
versions.  We may need to implement stencils that take
multiple arguments if they need differential operators
with non-constant coefficients.

4) Updaters can prevent fields from being deleted under
some conditions.

5) Blanca has requested some guard-cell fill optimizations
(.everywhere())

6) UserFunction could be useful for field operations.
(currently exists for array)

7) Some operations involving fields with expressions
don't work: (2 + f).comp(1) for example.

8) Two argument where isn't implemented for new field.

The first 5 are fairly important, the last few would be
nice for completeness (and would probably end up being
requested eventually).

    Stephen Smith


