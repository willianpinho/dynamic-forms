import XCTest
@testable import DataMapper
import Domain

final class DataMapperTests: XCTestCase {
    
    var formMapper: FormMapperImpl!
    var entryMapper: FormEntryMapperImpl!
    
    override func setUp() {
        super.setUp()
        formMapper = FormMapperImpl()
        entryMapper = FormEntryMapperImpl()
    }
    
    override func tearDown() {
        formMapper = nil
        entryMapper = nil
        super.tearDown()
    }
    
    func testFormMapperToDomain() throws {
        let data: [String: Any] = [
            "id": "test-form",
            "title": "Test Form",
            "fields": [
                [
                    "uuid": "field-1",
                    "type": "text",
                    "name": "test_field",
                    "label": "Test Field",
                    "required": true,
                    "value": "test value"
                ]
            ],
            "sections": [
                [
                    "uuid": "section-1",
                    "title": "Test Section",
                    "from": 0,
                    "to": 0,
                    "index": 0
                ]
            ]
        ]
        
        let form = try formMapper.mapToDomain(data)
        
        XCTAssertEqual(form.id, "test-form")
        XCTAssertEqual(form.title, "Test Form")
        XCTAssertEqual(form.fields.count, 1)
        XCTAssertEqual(form.sections.count, 1)
        
        let field = form.fields[0]
        XCTAssertEqual(field.uuid, "field-1")
        XCTAssertEqual(field.type, .text)
        XCTAssertEqual(field.name, "test_field")
        XCTAssertEqual(field.label, "Test Field")
        XCTAssertTrue(field.required)
        XCTAssertEqual(field.value, "test value")
    }
    
    func testFormMapperFromDomain() {
        let field = FormField(
            uuid: "field-1",
            type: .text,
            name: "test_field",
            label: "Test Field",
            required: true,
            value: "test value"
        )
        
        let section = FormSection(
            uuid: "section-1",
            title: "Test Section",
            from: 0,
            to: 0,
            index: 0
        )
        
        let form = DynamicForm(
            id: "test-form",
            title: "Test Form",
            fields: [field],
            sections: [section]
        )
        
        let data = formMapper.mapFromDomain(form)
        
        XCTAssertEqual(data["id"] as? String, "test-form")
        XCTAssertEqual(data["title"] as? String, "Test Form")
        
        let fieldsData = data["fields"] as? [[String: Any]]
        XCTAssertNotNil(fieldsData)
        XCTAssertEqual(fieldsData?.count, 1)
        
        let sectionsData = data["sections"] as? [[String: Any]]
        XCTAssertNotNil(sectionsData)
        XCTAssertEqual(sectionsData?.count, 1)
    }
    
    func testFormEntryMapperToDomain() throws {
        let data: [String: Any] = [
            "id": "entry-1",
            "formId": "form-1",
            "fieldValues": ["field-1": "value-1"],
            "isComplete": true,
            "isDraft": false,
            "createdAt": "2022-01-01T00:00:00.000Z",
            "updatedAt": "2022-01-01T00:00:00.000Z"
        ]
        
        let entry = try entryMapper.mapToDomain(data)
        
        XCTAssertEqual(entry.id, "entry-1")
        XCTAssertEqual(entry.formId, "form-1")
        XCTAssertEqual(entry.fieldValues["field-1"], "value-1")
        XCTAssertTrue(entry.isComplete)
        XCTAssertFalse(entry.isDraft)
    }
    
    func testFormEntryMapperFromDomain() {
        let entry = FormEntry(
            id: "entry-1",
            formId: "form-1",
            fieldValues: ["field-1": "value-1"],
            isComplete: true,
            isDraft: false
        )
        
        let data = entryMapper.mapFromDomain(entry)
        
        XCTAssertEqual(data["id"] as? String, "entry-1")
        XCTAssertEqual(data["formId"] as? String, "form-1")
        XCTAssertTrue(data["isComplete"] as? Bool ?? false)
        XCTAssertFalse(data["isDraft"] as? Bool ?? true)
        
        let fieldValues = data["fieldValues"] as? [String: String]
        XCTAssertEqual(fieldValues?["field-1"], "value-1")
    }
}