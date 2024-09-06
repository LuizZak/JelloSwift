**_Current stable release: v0.15.0_**

#### Develop trunk changelog:

- Dropped usage of SIMD in favor of multi-platform support (namely Linux/Windows).

---

## Stable Releases

## v0.15.0:

- Bumped target Swift version to 5.0.
- Now the library is distributed as a [Swift Package](https://swift.org/package-manager/), and the Cocoapods version is no longer maintained.
- `PointMass` is now a struct type. To change properties of individual point masses, use `Body.applyForce(_:toPointMassAt:)`, `Body.applyVelocity(_:toPointMassAt:)`, `Body.setVelocity(_:ofPointMassAt:)`, and `Body.setPosition(_:ofPointMassAt:)`.
- Now `BodyComponent.accumulateExternalForces` expects a `World` parameter as well.
- Deprecated `BodyComponent.accumulateExternalForces(on:relaxing:)`.

## v0.14.0:

- Bumped target Swift version to 4.2.

## v0.13.0:

- Bumped target Swift version to 4.1.
- Renamed `JointLinkType` to `JointLink`.
- Removed body parameter from init from body component classes. 

## v0.12.0:

- Fixing me meddling w/ pushed tags gone wrong ‌‌ఠి.ఠిన 

## v0.11.0:

- Deprecated methods where removed.
- Adding optional plasticity settings to internal springs and spring body joints. Plasticity permanently deforms a spring's resting distance over time as it stretches past a limiting yield. Plasticity is disabled by default.
- Correcting parameter lables/orderings in `SpringComponent`.
- Adding method `Body.withComponent<T: BodyComponent>(ofType:, do:)` that fetches a body component of a specified type and passes it to a closure, if it exists within a body.
- Fixing `Body.updateAABB()` w/ non-static bodies w/ `forceUpdate` flag set to `false`.
- Fixing `World.update()` calling `Body.updateEdgesAndNormals()` one more time than necessary.

## v0.10.0:

This is a breaking release. See bellow `BodyComponent` and `CollisionObserver` changes.

- Adding `World.relaxWorld()` and `World.relaxBodies()` that allows relaxing all/a set of bodies into a more proper rest shape that will not 'pop' into their rest shape when starting to simulate. Can be called at any time during simulaton.
- Making `BodyComponent` a protocol instead of a class.
- Removing deprecated `CollisionObserver.bodiesDidCollide(_ info: BodyCollisionInformation)` protocol method.

## v0.9.1:

- Adding macOS to supported platforms.

## v0.9.0:

This release affects behavior of simulations, specially ones using EdgeJointLinks!

- Allowing rest distance of internal body springs to be expressed using RestDistance, same way as body joints.
- Correcting implementation of edge link to properly calculate the mass of the link, and to apply proper torque on links that lie exactly half-way across the edge.
  This makes the edge act in a more natural way by applying proper torque to the affected body, as well as making it behave exactly as a PointJointLink when set at edge ratio 0 or 1.

## v0.8.0:

- Replacing '...' operator for ranged resting distance for body constraints with '<->' operator.
- Marking Vector2's inlineable implementations with `@inline(__always)` instead of `@_transparent` (easier to debug, as well).

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
