import XCTest
@testable import ClubItShared

final class ClubItSharedTests: XCTestCase {
    func testAppRoleMapping() {
        XCTAssertEqual(AppRole.from(dbRole: "Group SubLead"), .groupSubLead)
        XCTAssertEqual(AppRole.from(dbRole: "groupSubLead"), .groupSubLead)
        XCTAssertEqual(AppRole.from(dbRole: "group_sublead"), .groupSubLead)
        XCTAssertEqual(AppRole.from(dbRole: "level_1_sublead"), .groupSubLead)
        XCTAssertEqual(AppRole.from(dbRole: "vicePresident"), .groupSubLead)
        XCTAssertEqual(AppRole.from(dbRole: "vp"), .groupSubLead)
        XCTAssertEqual(AppRole.from(dbRole: "faculty"), .groupSubLead)
        
        XCTAssertEqual(AppRole.from(dbRole: "SubGroup Lead"), .subGroupLead)
        XCTAssertEqual(AppRole.from(dbRole: "subGroupLead"), .subGroupLead)
        XCTAssertEqual(AppRole.from(dbRole: "subgroup_lead"), .subGroupLead)
        XCTAssertEqual(AppRole.from(dbRole: "level_2_lead"), .subGroupLead)
        XCTAssertEqual(AppRole.from(dbRole: "clubLead"), .subGroupLead)
        
        XCTAssertEqual(AppRole.from(dbRole: "Group Lead"), .groupLead)
        XCTAssertEqual(AppRole.from(dbRole: "groupLead"), .groupLead)
        XCTAssertEqual(AppRole.from(dbRole: "group_lead"), .groupLead)
        XCTAssertEqual(AppRole.from(dbRole: "level_1_lead"), .groupLead)
        XCTAssertEqual(AppRole.from(dbRole: "president"), .groupLead)
        
        XCTAssertEqual(AppRole.from(dbRole: "SubGroup member"), .subGroupMember)
        XCTAssertEqual(AppRole.from(dbRole: "subGroupMember"), .subGroupMember)
        XCTAssertEqual(AppRole.from(dbRole: "subgroup_member"), .subGroupMember)
        XCTAssertEqual(AppRole.from(dbRole: "level_2_member"), .subGroupMember)
        
        XCTAssertEqual(AppRole.from(dbRole: "SuperAdmin"), .superAdmin)
        XCTAssertEqual(AppRole.from(dbRole: "superadmin"), .superAdmin)
        
        XCTAssertEqual(AppRole.from(dbRole: "Admin"), .admin)
        XCTAssertEqual(AppRole.from(dbRole: "admin"), .admin)
        
        XCTAssertEqual(AppRole.from(dbRole: "Guest"), .guest)
        XCTAssertEqual(AppRole.from(dbRole: "guest"), .guest)
        XCTAssertEqual(AppRole.from(dbRole: "student"), .guest)
    }
}
