//
//  RefundCalculatorTest.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/03.
//

import Foundation

// テスト用のメイン関数
func runRefundCalculatorTests() {
    let calculator = RegularRefundCalculator()

    print("🚃 JR定期券払い戻し計算テスト開始")

    // テストケース7: 6ヶ月定期（5ヶ月使用）
    test6MonthPass5MonthsUsed(calculator: calculator)

    print()

    // テストケース8: 6ヶ月定期（5日使用）
    test6MonthPass5DaysUsed(calculator: calculator)

    print("🎯 テスト完了")
}

// MARK: - テストケース

/// テストケース1: 1ヶ月定期（5日使用、7日以内）
func test1MonthPassWithin7Days(calculator: RegularRefundCalculator) {
    print("📝 テストケース1: 1ヶ月定期（5日使用、7日以内）")

    let startDate = createDate(year: 2025, month: 6, day: 1)!
    let refundDate = createDate(year: 2025, month: 6, day: 5)!

    let data = RefundData(
        startDate: startDate,
        passType: .oneMonth,
        purchasePrice: 10000,
        refundDate: refundDate,
        oneWayFare: 200,
        oneMonthFare: 8000,
        threeMonthFare: nil
    )

    let result = calculator.calculate(data: data)
    printResult(result: result, testCase: "1ヶ月定期（5日使用）")
}

/// テストケース2: 1ヶ月定期（15日使用、7日超）
func test1MonthPassOver7Days(calculator: RegularRefundCalculator) {
    print("📝 テストケース2: 1ヶ月定期（15日使用、7日超）")

    let startDate = createDate(year: 2025, month: 6, day: 1)!
    let refundDate = createDate(year: 2025, month: 6, day: 15)!

    let data = RefundData(
        startDate: startDate,
        passType: .oneMonth,
        purchasePrice: 10000,
        refundDate: refundDate,
        oneWayFare: 200,
        oneMonthFare: 8000,
        threeMonthFare: nil
    )

    let result = calculator.calculate(data: data)
    printResult(result: result, testCase: "1ヶ月定期（15日使用）")
}

/// テストケース3: 3ヶ月定期（1ヶ月使用）
func test3MonthPass1MonthUsed(calculator: RegularRefundCalculator) {
    print("📝 テストケース3: 3ヶ月定期（1ヶ月使用）")

    let startDate = createDate(year: 2025, month: 6, day: 1)!
    let refundDate = createDate(year: 2025, month: 6, day: 30)!

    let data = RefundData(
        startDate: startDate,
        passType: .threeMonths,
        purchasePrice: 28000,
        refundDate: refundDate,
        oneWayFare: 200,
        oneMonthFare: 10000,
        threeMonthFare: nil
    )

    let result = calculator.calculate(data: data)
    printResult(result: result, testCase: "3ヶ月定期（1ヶ月使用）")
}

/// テストケース4: 3ヶ月定期（2ヶ月使用）
func test3MonthPass2MonthsUsed(calculator: RegularRefundCalculator) {
    print("📝 テストケース4: 3ヶ月定期（2ヶ月使用）")

    let startDate = createDate(year: 2025, month: 6, day: 1)!
    let refundDate = createDate(year: 2025, month: 7, day: 31)!

    let data = RefundData(
        startDate: startDate,
        passType: .threeMonths,
        purchasePrice: 28000,
        refundDate: refundDate,
        oneWayFare: 200,
        oneMonthFare: 10000,
        threeMonthFare: nil
    )

    let result = calculator.calculate(data: data)
    printResult(result: result, testCase: "3ヶ月定期（2ヶ月使用）")
}

/// テストケース5: 6ヶ月定期（2ヶ月使用）
func test6MonthPass2MonthsUsed(calculator: RegularRefundCalculator) {
    print("📝 テストケース5: 6ヶ月定期（2ヶ月使用）")

    let startDate = createDate(year: 2025, month: 6, day: 1)!
    let refundDate = createDate(year: 2025, month: 7, day: 31)!

    let data = RefundData(
        startDate: startDate,
        passType: .sixMonths,
        purchasePrice: 50000,
        refundDate: refundDate,
        oneWayFare: 200,
        oneMonthFare: 10000,
        threeMonthFare: 28000
    )

    let result = calculator.calculate(data: data)
    printResult(result: result, testCase: "6ヶ月定期（2ヶ月使用）")
}

/// テストケース6: 6ヶ月定期（4ヶ月使用）
func test6MonthPass4MonthsUsed(calculator: RegularRefundCalculator) {
    print("📝 テストケース6: 6ヶ月定期（4ヶ月使用）")

    let startDate = createDate(year: 2025, month: 6, day: 1)!
    let refundDate = createDate(year: 2025, month: 9, day: 30)!

    let data = RefundData(
        startDate: startDate,
        passType: .sixMonths,
        purchasePrice: 50000,
        refundDate: refundDate,
        oneWayFare: 200,
        oneMonthFare: 10000,
        threeMonthFare: 28000
    )

    let result = calculator.calculate(data: data)
    printResult(result: result, testCase: "6ヶ月定期（4ヶ月使用）")
}

/// テストケース7: 6ヶ月定期（5ヶ月使用）
func test6MonthPass5MonthsUsed(calculator: RegularRefundCalculator) {
    print("📝 テストケース7: 6ヶ月定期（5ヶ月使用）")

    let startDate = createDate(year: 2025, month: 6, day: 1)!
    let refundDate = createDate(year: 2025, month: 10, day: 31)!

    let data = RefundData(
        startDate: startDate,
        passType: .sixMonths,
        purchasePrice: 50000,
        refundDate: refundDate,
        oneWayFare: 200,
        oneMonthFare: 10000,
        threeMonthFare: 28000
    )

    let result = calculator.calculate(data: data)
    printResult(result: result, testCase: "6ヶ月定期（5ヶ月使用）")
}

/// テストケース8: 6ヶ月定期（5日使用）
func test6MonthPass5DaysUsed(calculator: RegularRefundCalculator) {
    print("📝 テストケース8: 6ヶ月定期（5日使用）")

    let startDate = createDate(year: 2025, month: 6, day: 1)!
    let refundDate = createDate(year: 2025, month: 6, day: 5)!

    let data = RefundData(
        startDate: startDate,
        passType: .sixMonths,
        purchasePrice: 50000,
        refundDate: refundDate,
        oneWayFare: 200,
        oneMonthFare: 10000,
        threeMonthFare: 28000
    )

    let result = calculator.calculate(data: data)
    printResult(result: result, testCase: "6ヶ月定期（5日使用）")
}


// MARK: - ヘルパー関数

/// 日付を作成するヘルパー関数
func createDate(year: Int, month: Int, day: Int) -> Date? {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components)
}

/// 結果を整理して表示するヘルパー関数
func printResult(result: RefundResult, testCase: String) {
    print()
    print("🎯 結果 (\(testCase)):")
    print("   💰 払戻額: \(result.refundAmount)円")
    print("   📊 使用分運賃: \(result.usedAmount)円")
    print("   💳 手数料: \(result.processingFee)円")
    print("   📋 詳細: \(result.calculationDetails)")
    print()
}
