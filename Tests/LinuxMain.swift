import XCTest
@testable import JelloSwiftTests

XCTMain([
    testCase(JelloSwiftTests.allTests),
    testCase(AABBTests.allTests),
    testCase(BodyTests.allTests),
    testCase(ClosedShapeTests.allTests),
    testCase(GeomUtilsTests.allTests),
    testCase(PhysicsMathTest.allTests),
    testCase(PointMassTests.allTests),
    testCase(Vector2Tests.allTests),
])
