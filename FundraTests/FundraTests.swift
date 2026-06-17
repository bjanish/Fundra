//
//  FundraTests.swift
//  FundraTests
//
//  Created by Brian Janish on 6/10/26.
//

import XCTest
@testable import Fundra

final class FundraTests: XCTestCase {

    // MARK: - filterAmountInput Tests
    
    func testFilterAllowsDigits() {
        XCTAssertEqual(filterAmountInput("12345"), "12345")
    }
    
    func testFilterAllowsSingleDecimalPoint() {
        XCTAssertEqual(filterAmountInput("123.45"), "123.45")
    }
    
    func testFilterRemovesMultipleDecimalPoints() {
        XCTAssertEqual(filterAmountInput("1.2.3"), "1.23")
    }
    
    func testFilterRemovesLetters() {
        XCTAssertEqual(filterAmountInput("12abc34"), "1234")
    }
    
    func testFilterRemovesSpecialCharacters() {
        XCTAssertEqual(filterAmountInput("$1,000!"), "1,000")
    }
    
    func testFilterLimitsTwoDecimalPlaces() {
        XCTAssertEqual(filterAmountInput("100.999"), "100.99")
    }
    
    func testFilterAllowsExactlyTwoDecimalPlaces() {
        XCTAssertEqual(filterAmountInput("100.99"), "100.99")
    }
    
    func testFilterAllowsOneDecimalPlace() {
        XCTAssertEqual(filterAmountInput("100.5"), "100.5")
    }
    
    func testFilterAllowsCommas() {
        XCTAssertEqual(filterAmountInput("10,000"), "10,000")
    }
    
    func testFilterEmptyString() {
        XCTAssertEqual(filterAmountInput(""), "")
    }
    
    func testFilterOnlyDecimalPoint() {
        XCTAssertEqual(filterAmountInput("."), ".")
    }
    
    func testFilterDecimalAtStart() {
        XCTAssertEqual(filterAmountInput(".99"), ".99")
    }
    
    // MARK: - abbreviatedAmount Tests
    
    func testAbbreviatedMillions() {
        XCTAssertEqual(abbreviatedAmount(1_500_000), "$1.5M")
    }
    
    func testAbbreviatedHundredThousands() {
        XCTAssertEqual(abbreviatedAmount(250_000), "$250K")
    }
    
    func testAbbreviatedTenThousands() {
        XCTAssertEqual(abbreviatedAmount(15_000), "$15.0K")
    }
    
    func testAbbreviatedBelowTenThousand() {
        XCTAssertEqual(abbreviatedAmount(5_000), "$5,000")
    }
    
    func testAbbreviatedZero() {
        XCTAssertEqual(abbreviatedAmount(0), "$0")
    }
    
    // MARK: - formatFullAmount Tests
    
    func testFormatWholeNumber() {
        XCTAssertEqual(formatFullAmount(1000), "$1,000")
    }
    
    func testFormatWithCents() {
        XCTAssertEqual(formatFullAmount(1000.50), "$1,000.50")
    }
    
    func testFormatZero() {
        XCTAssertEqual(formatFullAmount(0), "$0")
    }
    
    func testFormatSmallAmount() {
        XCTAssertEqual(formatFullAmount(3.99), "$3.99")
    }
    
    func testFormatLargeWholeNumber() {
        XCTAssertEqual(formatFullAmount(100000), "$100,000")
    }
}
