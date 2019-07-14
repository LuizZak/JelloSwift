import JelloSwift

class BodyRayComponent: BodyComponent {
    var color: Color4 = Color4.fromUIntARGB(0xFFFF0000)
    var rayLength: JFloat = 1
    var ignoreJoinedBodies: Bool = true
    
    required init() {
        
    }
    
    func accumulateInternalForces(in body: Body, relaxing: Bool) {
        
    }
    
    func accumulateExternalForces(on body: Body, world: World, relaxing: Bool) {
        
    }
}
