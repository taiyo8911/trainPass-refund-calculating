//
//  SectionChangeRefundCalculator.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/03.
//

import Foundation

// MARK: - 区間変更計算の詳細情報

struct SectionChangeCalculationDetail {
    let junCalculation: String
    let dailyFareCalculation: String
    let usedFareCalculation: String
    let finalCalculation: String
}

// MARK: - 区間変更データ検証

class SectionChangeDataValidator {
    enum ValidationError: Error {
        case refundDateBeforeStart
        case refundDateTooFarInFuture

        var message: String {
            switch self {
            case .refundDateBeforeStart:
                return "払戻日は開始日以降である必要があります"
            case .refundDateTooFarInFuture:
                return "払戻日が現実的な範囲を超えています"
            }
        }
    }

    func validate(_ data: SectionChangeRefundData) -> Result<Void, ValidationError> {
        if data.refundDate < data.startDate {
            return .failure(.refundDateBeforeStart)
        }

        // 区間変更払戻では終了日の概念がないため、現実的な上限をチェック
        let calendar = Calendar.current
        let maxRefundDate = calendar.date(byAdding: .month, value: 6, to: data.startDate) ?? data.startDate
        if data.refundDate > maxRefundDate {
            return .failure(.refundDateTooFarInFuture)
        }

        return .success(())
    }
}

// MARK: - 区間変更計算エンジン

class SectionChangeCalculationEngine {

    func calculate(_ data: SectionChangeRefundData) -> (RefundResult, SectionChangeCalculationDetail) {
        // 使用分運賃を計算
        let usedFare = data.usedJun * data.dailyFare * 10

        // 最終払戻額を計算
        let refundAmount = max(0, data.purchasePrice - usedFare - data.processingFee)

        // 計算詳細を作成
        let detail = createCalculationDetail(data, usedFare: usedFare, refundAmount: refundAmount)

        // 結果を作成
        let result = RefundResult(
            refundAmount: refundAmount,
            usedAmount: usedFare,
            processingFee: data.processingFee,
            calculationDetails: "区間変更払戻: 使用\(data.usedJun)旬、日割運賃\(data.dailyFare)円/日"
        )

        return (result, detail)
    }

    private func createCalculationDetail(_ data: SectionChangeRefundData, usedFare: Int, refundAmount: Int) -> SectionChangeCalculationDetail {
        // 旬数計算の詳細
        let junDetail: String
        if data.elapsedDays % 10 == 0 {
            junDetail = "\(data.elapsedDays)日 ÷ 10 = \(data.usedJun)旬（ちょうど）"
        } else {
            let fullJun = data.elapsedDays / 10
            let remainder = data.elapsedDays % 10
            junDetail = "\(data.elapsedDays)日 = \(fullJun)旬 + \(remainder)日 → \(data.usedJun)旬（端数切り上げ）"
        }

        // 日割運賃計算の詳細（修正：購入価格ベースの計算に変更）
        // すべての定期券種別で購入価格を基準とする統一的なアプローチ
        let dailyFareDetail: String
        switch data.passType {
        case .oneMonth:
            dailyFareDetail = "\(data.purchasePrice)円 ÷ \(CalculationConstants.oneMonthDays)日 = \(data.dailyFare)円/日（切り上げ）"
        case .threeMonths:
            dailyFareDetail = "\(data.purchasePrice)円 ÷ \(CalculationConstants.threeMonthDays)日 = \(data.dailyFare)円/日（切り上げ）"
        case .sixMonths:
            dailyFareDetail = "\(data.purchasePrice)円 ÷ \(CalculationConstants.sixMonthDays)日 = \(data.dailyFare)円/日（切り上げ）"
        }

        return SectionChangeCalculationDetail(
            junCalculation: junDetail,
            dailyFareCalculation: dailyFareDetail,
            usedFareCalculation: "\(data.usedJun)旬 × \(data.dailyFare)円 × 10 = \(usedFare)円",
            finalCalculation: "\(data.purchasePrice)円 - \(usedFare)円 - \(data.processingFee)円 = \(refundAmount)円"
        )
    }
}

// MARK: - 区間変更ログ出力

class SectionChangeCalculationLogger {
    private var isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func logCalculation(_ data: SectionChangeRefundData, result: RefundResult, detail: SectionChangeCalculationDetail) {
        guard isEnabled else { return }

        print("=== 区間変更払い戻し計算 ===")
        print()
        logBasicInfo(data)
        logCalculationDetail(detail)
        logResult(result)
        print()
    }

    func logError(_ error: SectionChangeDataValidator.ValidationError) {
        guard isEnabled else { return }
        print("❌ エラー: \(error.message)")
        print()
    }

    private func logBasicInfo(_ data: SectionChangeRefundData) {
        print("✅ 基本情報")
        print("   定期券種別: \(data.passType.description)")
        print("   購入価格: \(data.purchasePrice)円")
        print("   開始日: \(formatDate(data.startDate))")
        print("   払戻日: \(formatDate(data.refundDate))")
        print("   使用日数: \(data.elapsedDays)日")
        print()
    }

    private func logCalculationDetail(_ detail: SectionChangeCalculationDetail) {
        print("📊 計算詳細")
        print("   旬数計算: \(detail.junCalculation)")
        print("   日割運賃: \(detail.dailyFareCalculation)")
        print("   使用分運賃: \(detail.usedFareCalculation)")
        print("   最終計算: \(detail.finalCalculation)")
        print()
    }

    private func logResult(_ result: RefundResult) {
        if result.refundAmount > 0 {
            print("✅ 計算結果")
            print("   最終払戻額: \(result.refundAmount)円")
        } else {
            print("❌ 払戻不可")
            print("   理由: 使用分運賃が購入価格を上回るため")
        }
    }

    private func formatDate(_ date: Date) -> String {
        return CommonDateFormatters.standard.string(from: date)
    }
}

// MARK: - 区間変更統合クラス

class SectionChangeRefundCalculator {
    private let validator = SectionChangeDataValidator()
    private let engine = SectionChangeCalculationEngine()
    private let logger: SectionChangeCalculationLogger

    init(enableLogging: Bool = true) {
        self.logger = SectionChangeCalculationLogger(isEnabled: enableLogging)
    }

    /// 区間変更払い戻し計算のメインエントリーポイント
    func calculate(data: SectionChangeRefundData) -> RefundResult {
        // 1. 入力検証
        switch validator.validate(data) {
        case .success:
            break
        case .failure(let error):
            logger.logError(error)
            return RefundResult(
                refundAmount: 0,
                usedAmount: 0,
                processingFee: data.processingFee,
                calculationDetails: "エラー: \(error.message)"
            )
        }

        // 2. 計算実行
        let (result, detail) = engine.calculate(data)

        // 3. ログ出力
        logger.logCalculation(data, result: result, detail: detail)

        return result
    }

    /// ログ出力なしの計算（テスト用など）
    func calculateSilently(data: SectionChangeRefundData) -> RefundResult {
        let originalCalculator = SectionChangeRefundCalculator(enableLogging: false)
        return originalCalculator.calculate(data: data)
    }
}

// MARK: - デモクラス（簡略化）

class SectionChangeRefundDemo {
    private let calculator = SectionChangeRefundCalculator()

    func runDemo() {
        print("=== 区間変更払い戻し計算システム デモ ===\n")

        let testCases = createTestCases()

        for (index, testCase) in testCases.enumerated() {
            print("【ケース\(index + 1): \(testCase.description)】")
            let result = calculator.calculate(data: testCase.data)

            if result.refundAmount > 0 {
                print("✅ 成功: 払戻額 \(result.refundAmount)円")
            } else {
                print("❌ \(result.calculationDetails)")
            }
            print("---")
            print()
        }
    }

    private func createTestCases() -> [(description: String, data: SectionChangeRefundData)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return [
            (
                description: "正常な区間変更払い戻し（37日使用）",
                data: SectionChangeRefundData(
                    startDate: dateFormatter.date(from: "2025-02-07")!,
                    passType: .threeMonths,
                    purchasePrice: 45000,
                    refundDate: dateFormatter.date(from: "2025-03-16")!
                )
            ),
            (
                description: "旬数計算の境界テスト（10日ちょうど）",
                data: SectionChangeRefundData(
                    startDate: dateFormatter.date(from: "2025-02-07")!,
                    passType: .oneMonth,
                    purchasePrice: 16000,
                    refundDate: dateFormatter.date(from: "2025-02-16")!
                )
            ),
            (
                description: "旬数計算の境界テスト（11日）",
                data: SectionChangeRefundData(
                    startDate: dateFormatter.date(from: "2025-02-07")!,
                    passType: .threeMonths,
                    purchasePrice: 45000,
                    refundDate: dateFormatter.date(from: "2025-02-17")!
                )
            )
        ]
    }
}
