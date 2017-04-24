**_Current stable release: v0.8.0_**

#### Develop trunk changelog:

- Trunk is clean!

## Stable Releases
---

## v0.8.0:

- Replacing '...' operator for ranged resting distance for body constraints with '<->' operator.
- Marking Vector2's inlineable implementations with @inline(__always) instead of @_transparent (easier to debug, as well).

## v0.5.1:

- Using unchecked arithmetic operators in some tight loops that we know won't overlow under reasonable circumstances.

## v0.5.0:

- Making corrections to method parameter labeling on Vector2 methods to make them more idiomatic to swift.
- Adding `World.bodiesIntersecting(closedShape:at:)` to query bodies that intersect a specified closed shape in world space.
- Adding @_transparent annotations to some members of Vector2 that really don't have to be opaque.

Note: Some operations with transformation of Vector2 lists using ClosedShape w/ rotations might become slightly more imprecise due to usage of Matrices to reduce calls to cos/sin.

## v0.4.0:

- Fixing crash issue with `nan` floats generated during body point mass normal calculation.
- Adding support for Vector2 affine transformations using simd to allow speeding up operations.
- Now the optimized build builds with -Owholemodule.
- Added `ClosedShape.create` static method.

## v0.3.0:

- Re-working API of `ClosedShape` to flow more naturally when coding.
- Re-working `BodyJoint.restDistance` property to be an enumeration with two distinct values: `case fixed(CGFloat)` and `case ranged(min: CGFloat, max: CGFloat)`. This change simply aims to collapse the old `restDistance` and `maxRestDistance` into a more cohese format.
    - This enum can be created by int/double literals and from the range operator `...` between two CGFloat values.
- Adding a small fix for a case where NaN would cause crashes during collision resolving.

## v0.2.0:

- First public Cocoapods release.
