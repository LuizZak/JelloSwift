#if arch(x86_64) || arch(arm64)

/// Represents the standard floating point type used by JelloSwift.
/// It is a double precision floating point in 64-bits platforms, and
/// single-precision in 32-bit platforms.
///
/// Currently: Double
public typealias JFloat = Double

#elseif arch(i386) || arch(arm)

/// Represents the standard floating point type used by JelloSwift.
/// It is a double precision floating point in 64-bits platforms, and
/// single-precision in 32-bit platforms.
///
/// Currently: Float
public typealias JFloat = Float

#endif
