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

    /// Gets a value specifying whether this joint link supports angling.
    var supportsAngling: Bool { get }

    /// The angle of the joint link.
    /// For body and shape joints, this is the angle of the body's rotational
    /// axis, for edge joints, this is the angle of the edge, and for point
    /// joints, this is the normal of the point.
    var angle: JFloat { get }

    /// The angular velocity of the joint link, or the amount of rotation this
    /// joint is experiencing in radians/s.
    var angularVelocity: JFloat { get }

    /// Applies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    func applyForce(of force: Vector2)

    /// Applies a torque (rotational) force to the subject of this joint link.
    /// If this joint does not support angling, this results in no change.
    ///
    /// - Parameter force: A torque force to apply to the subject of this joint
    /// link.
    func applyTorque(_ force: JFloat)

    /// Applies a direct positional translation of this joint link by a given
    /// offset.
    ///
    /// - parameter offset: An offset to apply to the member(s) of this joint link.
    func translate(by offset: Vector2)

    /// Changes the coordinate system of this joint link's components to the one
    /// specified.
    ///
    /// Relative positional movement is performed across all components, for a
    /// shape or edge link, across the entire body for a body link, and for a
    /// single point mass, for a point mass link.
    func moveTo(_ position: Vector2)
}

public extension JointLink {
    func moveTo(_ position: Vector2) {
        let relative = position - self.position
        translate(by: relative)
    }
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
