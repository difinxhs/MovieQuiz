import XCTest
@testable import MovieQuiz

class ArrayTests: XCTestCase {
    func testGetValueInRange() throws { // тест на успешное взятие элемента по индексу
        //given
        let array = [1,1,2,3,5]
        
        //when
        let value = array[safe: 2]
        
        //then
        XCTAssertNotNil(value)
        XCTAssertEqual(value, 2)
    }
    
    func testGetValueOutOfRange() throws { // тест на взятие элемента по неправильному индексу
        //given
        let array = [1,1,2,3,5]
        
        //when
        let value = array[safe: 20]
        
        //then
        XCTAssertNil(value)
    }
}
