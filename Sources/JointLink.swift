/// Protocol to be implemented by objects that specify the way a joint links
/// with a body
public protocol JointLink {
    /// Gets the body that this joint link is linked to.
    /// Must be unowned, as to not trigger a retain cycle between the joint link
    /// and the body it is attached to.
    var body: Body { get }

    /// Gets the type of joint this joint link represents
    var linkType: LinkType { get }

    /// Gets the position, in world coordinates, at which this joint links with
    /// the underlying body
    var position: Vector2 { get }

    /// Gets the velocity of the object this joint links to
    var velocity: Vector2 { get }

    /// Gets the total mass of the subject of this joint link
    var mass: JFloat { get }

    /// Gets a value specifying whether the object referenced by this
    /// JointLinkType is static
    var isStatic: Bool { get }

    /// Applies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    func applyForce(of force: Vector2)

    /// Applies a direct positional translation of this joint link by a given
    /// offset.
    ///
    /// - parameter offset: An offset to apply to the member(s) of this joint link.
    func translate(by offset: Vector2)
}

/// The type of joint link of a BodyJointLink class
public enum LinkType: Int, Codable {
    /// Specifies that the joint links at the whole body, relative to the center
    case body

    /// Specifies that the joint links at a body's point
    case point

    /// Specifies that the joint links at a body's edge (set of two points)
    case edge

    /// Specifies that the joint links at an arbitrary set of points of a body
    case shape
}
