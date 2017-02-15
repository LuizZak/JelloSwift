**_Current stable release: v0.3.0_**

#### Develop trunk changelog:

- Trunk is clean!

## Stable Releases
---

## v0.3.0:

- Re-working API of `ClosedShape` to flow more naturally when coding.
- Re-working `BodyJoint.restDistance` property to be an enumeration with two distinct values: `case fixed(CGFloat)` and `case ranged(min: CGFloat, max: CGFloat)`. This change simply aims to collapse the old `restDistance` and `maxRestDistance` into a more cohese format.
    - This enum can be created by int/double literals and from the range operator `...` between two CGFloat values.
- Adding a small fix for a case where NaN would cause crashes during collision resolving.

## v0.2.0:

- First public Cocoapods release.
