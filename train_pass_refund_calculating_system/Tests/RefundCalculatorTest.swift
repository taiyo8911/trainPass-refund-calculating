//
//  RefundCalculatorTest.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/09.
//

import Foundation

/// 定期券払戻計算のテストケース（修正版）
/// 修正した計算ロジックに対応したテストを実装
class RefundCalculatorTest {
    
    private let regularCalculator = RegularRefundCalculator(enableLogging: true)
    private let sectionChangeCalculator = SectionChangeRefundCalculator(enableLogging: true)
    
    /// 全テストケースを実行
    func runAllTests() {
        print("=== 定期券払戻計算システム 総合テスト ===\n")
        
        // 通常払戻テスト
        runRegularRefundTests()
        
        print("\n" + "="*50 + "\n")
        
        // 区間変更払戻テスト
        runSectionChangeRefundTests()
        
        print("\n" + "="*50 + "\n")
        
        // 境界値テスト
        runBoundaryTests()
        
        print("\n=== テスト完了 ===")
    }
    
    // MARK: - 通常払戻テスト
    
    private func runRegularRefundTests() {
        print("【通常払戻テスト】\n")
        
        let testCases = createRegularRefundTestCases()
        
        for (index, testCase) in testCases.enumerated() {
            print("テストケース\(index + 1): \(testCase.description)")
            let result = regularCalculator.calculate(data: testCase.data)
            
            // 期待値との比較
            let success = validateResult(result, expected: testCase.expected)
            print(success ? "✅ 合格" : "❌ 不合格")
            print("期待値: 払戻額\(testCase.expected.refundAmount)円, 使用分\(testCase.expected.usedAmount)円")
            print("実際値: 払戻額\(result.refundAmount)円, 使用分\(result.usedAmount)円")
            print("---\n")
        }
    }
    
    private func createRegularRefundTestCases() -> [(description: String, data: RefundData, expected: RefundResult)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return [
            // テスト1: 1ヶ月定期（5日使用、7日以内）
            (
                description: "1ヶ月定期 5日使用（7日以内ルール適用）",
                data: RefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .oneMonth,
                    purchasePrice: 16000,
                    refundDate: dateFormatter.date(from: "2025-06-09")!, // 5日使用
                    oneWayFare: 320,
                    oneMonthFare: 16000,
                    threeMonthFare: nil
                ),
                expected: RefundResult(
                    refundAmount: 12580, // 16000 - (320*2*5) - 220
                    usedAmount: 3200,    // 320*2*5
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト2: 1ヶ月定期（15日使用、7日超）
            (
                description: "1ヶ月定期 15日使用（8日以降は払戻不可）",
                data: RefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .oneMonth,
                    purchasePrice: 16000,
                    refundDate: dateFormatter.date(from: "2025-06-19")!, // 15日使用
                    oneWayFare: 320,
                    oneMonthFare: 16000,
                    threeMonthFare: nil
                ),
                expected: RefundResult(
                    refundAmount: 0,     // 払戻不可
                    usedAmount: 0,
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト3: 3ヶ月定期（1ヶ月使用）- 修正版
            (
                description: "3ヶ月定期 1ヶ月使用（月単位計算）",
                data: RefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .threeMonths,
                    purchasePrice: 45000,
                    refundDate: dateFormatter.date(from: "2025-07-04")!, // 30日使用（1ヶ月目の最終日）
                    oneWayFare: 500,
                    oneMonthFare: 16000,
                    threeMonthFare: nil
                ),
                expected: RefundResult(
                    refundAmount: 28780, // 45000 - 16000 - 220
                    usedAmount: 16000,   // 1ヶ月定期運賃
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト4: 3ヶ月定期（2ヶ月使用）- 修正版
            (
                description: "3ヶ月定期 2ヶ月使用（月単位計算）",
                data: RefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .threeMonths,
                    purchasePrice: 45000,
                    refundDate: dateFormatter.date(from: "2025-08-04")!, // 2ヶ月目の最終日
                    oneWayFare: 500,
                    oneMonthFare: 16000,
                    threeMonthFare: nil
                ),
                expected: RefundResult(
                    refundAmount: 12780, // 45000 - 32000 - 220
                    usedAmount: 32000,   // 16000 * 2ヶ月
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト5: 6ヶ月定期（2ヶ月使用）
            (
                description: "6ヶ月定期 2ヶ月使用（3ヶ月未満）",
                data: RefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .sixMonths,
                    purchasePrice: 80000,
                    refundDate: dateFormatter.date(from: "2025-08-04")!, // 2ヶ月使用
                    oneWayFare: 500,
                    oneMonthFare: 16000,
                    threeMonthFare: 45000
                ),
                expected: RefundResult(
                    refundAmount: 47780, // 80000 - 32000 - 220
                    usedAmount: 32000,   // 16000 * 2ヶ月
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト6: 6ヶ月定期（4ヶ月使用）- 修正版
            (
                description: "6ヶ月定期 4ヶ月使用（3ヶ月以上使用）",
                data: RefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .sixMonths,
                    purchasePrice: 80000,
                    refundDate: dateFormatter.date(from: "2025-10-04")!, // 4ヶ月使用
                    oneWayFare: 500,
                    oneMonthFare: 16000,
                    threeMonthFare: 45000
                ),
                expected: RefundResult(
                    refundAmount: 18780, // 80000 - (45000 + 16000) - 220
                    usedAmount: 61000,   // 45000 + 16000 (3ヶ月分 + 1ヶ月分)
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト7: 7日以内の境界テスト
            (
                description: "3ヶ月定期 7日使用（境界値テスト）",
                data: RefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .threeMonths,
                    purchasePrice: 45000,
                    refundDate: dateFormatter.date(from: "2025-06-11")!, // 7日使用
                    oneWayFare: 500,
                    oneMonthFare: 16000,
                    threeMonthFare: nil
                ),
                expected: RefundResult(
                    refundAmount: 37780, // 45000 - (500*2*7) - 220
                    usedAmount: 7000,    // 500*2*7
                    processingFee: 220,
                    calculationDetails: ""
                )
            )
        ]
    }
    
    // MARK: - 区間変更払戻テスト
    
    private func runSectionChangeRefundTests() {
        print("【区間変更払戻テスト】\n")
        
        let testCases = createSectionChangeRefundTestCases()
        
        for (index, testCase) in testCases.enumerated() {
            print("テストケース\(index + 1): \(testCase.description)")
            let result = sectionChangeCalculator.calculate(data: testCase.data)
            
            // 期待値との比較
            let success = validateResult(result, expected: testCase.expected)
            print(success ? "✅ 合格" : "❌ 不合格")
            print("期待値: 払戻額\(testCase.expected.refundAmount)円, 使用分\(testCase.expected.usedAmount)円")
            print("実際値: 払戻額\(result.refundAmount)円, 使用分\(result.usedAmount)円")
            print("---\n")
        }
    }
    
    private func createSectionChangeRefundTestCases() -> [(description: String, data: SectionChangeRefundData, expected: RefundResult)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return [
            // テスト1: 1ヶ月定期 15日使用（2旬）
            (
                description: "1ヶ月定期 15日使用（2旬）",
                data: SectionChangeRefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .oneMonth,
                    purchasePrice: 16000,
                    refundDate: dateFormatter.date(from: "2025-06-19")! // 15日使用
                ),
                expected: RefundResult(
                    refundAmount: 5113,  // 16000 - (534*2*10) - 220 = 16000 - 10680 - 220
                    usedAmount: 10680,   // ceil(16000/30) = 534円/日, 2旬 = 534*2*10
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト2: 3ヶ月定期 37日使用（4旬）
            (
                description: "3ヶ月定期 37日使用（4旬）",
                data: SectionChangeRefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .threeMonths,
                    purchasePrice: 45000,
                    refundDate: dateFormatter.date(from: "2025-07-11")! // 37日使用
                ),
                expected: RefundResult(
                    refundAmount: 24820, // 45000 - (500*4*10) - 220 = 45000 - 20000 - 220
                    usedAmount: 20000,   // ceil(45000/90) = 500円/日, 4旬 = 500*4*10
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト3: 6ヶ月定期 55日使用（6旬）
            (
                description: "6ヶ月定期 55日使用（6旬）",
                data: SectionChangeRefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .sixMonths,
                    purchasePrice: 80000,
                    refundDate: dateFormatter.date(from: "2025-07-29")! // 55日使用
                ),
                expected: RefundResult(
                    refundAmount: 53113, // 80000 - (445*6*10) - 220 = 80000 - 26700 - 220
                    usedAmount: 26700,   // ceil(80000/180) = 445円/日, 6旬 = 445*6*10
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト4: 旬数計算の境界テスト（10日ちょうど）
            (
                description: "旬数境界テスト 10日使用（1旬ちょうど）",
                data: SectionChangeRefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .oneMonth,
                    purchasePrice: 16000,
                    refundDate: dateFormatter.date(from: "2025-06-14")! // 10日使用
                ),
                expected: RefundResult(
                    refundAmount: 10440, // 16000 - (534*1*10) - 220 = 16000 - 5340 - 220
                    usedAmount: 5340,    // ceil(16000/30) = 534円/日, 1旬 = 534*1*10
                    processingFee: 220,
                    calculationDetails: ""
                )
            ),
            
            // テスト5: 旬数計算の境界テスト（11日使用）
            (
                description: "旬数境界テスト 11日使用（2旬に切り上げ）",
                data: SectionChangeRefundData(
                    startDate: dateFormatter.date(from: "2025-06-05")!,
                    passType: .oneMonth,
                    purchasePrice: 16000,
                    refundDate: dateFormatter.date(from: "2025-06-15")! // 11日使用
                ),
                expected: RefundResult(
                    refundAmount: 5100,  // 16000 - (534*2*10) - 220 = 16000 - 10680 - 220
                    usedAmount: 10680,   // ceil(16000/30) = 534円/日, 2旬 = 534*2*10
                    processingFee: 220,
                    calculationDetails: ""
                )
            )
        ]
    }
    
    // MARK: - 境界値テスト
    
    private func runBoundaryTests() {
        print("【境界値テスト】\n")
        
        testSevenDayBoundary()
        testMonthBoundary()
        testCalculationConstants()
    }
    
    private func testSevenDayBoundary() {
        print("7日境界テスト:")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 7日使用（7日以内ルール適用）
        let data7Days = RefundData(
            startDate: dateFormatter.date(from: "2025-06-05")!,
            passType: .threeMonths,
            purchasePrice: 45000,
            refundDate: dateFormatter.date(from: "2025-06-11")!,
            oneWayFare: 500,
            oneMonthFare: 16000,
            threeMonthFare: nil
        )
        
        // 8日使用（月単位計算）
        let data8Days = RefundData(
            startDate: dateFormatter.date(from: "2025-06-05")!,
            passType: .threeMonths,
            purchasePrice: 45000,
            refundDate: dateFormatter.date(from: "2025-06-12")!,
            oneWayFare: 500,
            oneMonthFare: 16000,
            threeMonthFare: nil
        )
        
        let result7 = regularCalculator.calculateSilently(data: data7Days)
        let result8 = regularCalculator.calculateSilently(data: data8Days)
        
        print("7日使用: 払戻額\(result7.refundAmount)円（7日以内ルール）")
        print("8日使用: 払戻額\(result8.refundAmount)円（月単位計算）")
        print()
    }
    
    private func testMonthBoundary() {
        print("月境界テスト（使用月数計算）:")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 6月5日開始のケース
        let testDates = [
            ("2025-07-04", "1ヶ月目最終日"),
            ("2025-07-05", "2ヶ月目開始日"),
            ("2025-08-04", "2ヶ月目最終日"),
            ("2025-08-05", "3ヶ月目開始日")
        ]
        
        for (dateString, description) in testDates {
            let data = RefundData(
                startDate: dateFormatter.date(from: "2025-06-05")!,
                passType: .threeMonths,
                purchasePrice: 45000,
                refundDate: dateFormatter.date(from: dateString)!,
                oneWayFare: 500,
                oneMonthFare: 16000,
                threeMonthFare: nil
            )
            
            let result = regularCalculator.calculateSilently(data: data)
            print("\(description): 使用\(data.usedMonths)ヶ月, 払戻額\(result.refundAmount)円")
        }
        print()
    }
    
    private func testCalculationConstants() {
        print("定数テスト:")
        print("手数料: \(CalculationConstants.processingFee)円")
        print("7日以内境界: \(CalculationConstants.withinSevenDaysThreshold)日")
        print("1ヶ月基準日数: \(CalculationConstants.oneMonthDays)日")
        print("3ヶ月基準日数: \(CalculationConstants.threeMonthDays)日")
        print("6ヶ月基準日数: \(CalculationConstants.sixMonthDays)日")
        print()
    }
    
    // MARK: - ヘルパーメソッド
    
    private func validateResult(_ actual: RefundResult, expected: RefundResult) -> Bool {
        return actual.refundAmount == expected.refundAmount &&
               actual.usedAmount == expected.usedAmount &&
               actual.processingFee == expected.processingFee
    }
}

// MARK: - テスト実行用デモクラス

class TestRunner {
    static func runAllTests() {
        let tester = RefundCalculatorTest()
        tester.runAllTests()
    }
}

// MARK: - String拡張（テスト用）

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
