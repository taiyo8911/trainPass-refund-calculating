//
//  RegularRefundCalculator.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/03.
//

import Foundation

// MARK: - 計算結果の詳細情報

/// 計算過程の詳細情報
struct RefundCalculationDetail {
    let calculationMethod: CalculationMethod
    let usedDays: Int
    let usedMonths: Int
    let appliedRule: String
    let calculationSteps: [String]

    enum CalculationMethod {
        case withinSevenDays
        case monthlyCalculation
        case noRefund
    }
}

// MARK: - データ検証

class RefundDataValidator {
    enum ValidationError: Error {
        case refundDateBeforeStart
        case refundDateAfterEnd
        case missingThreeMonthFare

        var message: String {
            switch self {
            case .refundDateBeforeStart:
                return "払戻日は開始日以降である必要があります"
            case .refundDateAfterEnd:
                return "払戻日は終了日以前である必要があります"
            case .missingThreeMonthFare:
                return "6ヶ月定期の払戻では3ヶ月定期運賃の入力が必要です"
            }
        }
    }

    func validate(_ data: RefundData) -> Result<Void, ValidationError> {
        if data.refundDate < data.startDate {
            return .failure(.refundDateBeforeStart)
        }

        if data.refundDate > data.endDate {
            return .failure(.refundDateAfterEnd)
        }

        if data.passType == .sixMonths && data.threeMonthFare == nil {
            return .failure(.missingThreeMonthFare)
        }

        return .success(())
    }
}

// MARK: - 計算エンジン（純粋なビジネスロジック）

class RefundCalculationEngine {

    func calculate(_ data: RefundData) -> (RefundResult, RefundCalculationDetail) {
        // 7日以内かどうかで計算方法を分岐
        if data.elapsedDays <= 7 {
            return calculateWithinSevenDays(data)
        } else {
            return calculateMonthlyBasis(data)
        }
    }

    // MARK: - 7日以内の計算

    private func calculateWithinSevenDays(_ data: RefundData) -> (RefundResult, RefundCalculationDetail) {
        let usedAmount = data.roundTripFare * data.elapsedDays
        let refundAmount = max(0, data.purchasePrice - usedAmount - data.processingFee)

        let detail = RefundCalculationDetail(
            calculationMethod: .withinSevenDays,
            usedDays: data.elapsedDays,
            usedMonths: 0,
            appliedRule: "使用開始から7日以内の特別計算",
            calculationSteps: [
                "使用分運賃 = \(data.roundTripFare)円 × \(data.elapsedDays)日 = \(usedAmount)円",
                "払戻額 = \(data.purchasePrice)円 - \(usedAmount)円 - \(data.processingFee)円 = \(refundAmount)円"
            ]
        )

        let result = RefundResult(
            refundAmount: refundAmount,
            usedAmount: usedAmount,
            processingFee: data.processingFee,
            calculationDetails: detail.appliedRule
        )

        return (result, detail)
    }

    // MARK: - 月単位計算

    private func calculateMonthlyBasis(_ data: RefundData) -> (RefundResult, RefundCalculationDetail) {
        // 1ヶ月定期の場合は7日以降は払戻なし
        if data.passType == .oneMonth {
            return createNoRefundResult(data, reason: "1ヶ月定期は使用開始から7日以降は払戻不可")
        }

        // 残存期間チェック
        if data.remainingMonths < 1 {
            return createNoRefundResult(data, reason: "残存期間が1ヶ月未満のため払戻不可")
        }

        // 使用分運賃を計算
        let usedFare = calculateUsedFare(data)
        let calculationResult = data.purchasePrice - usedFare - data.processingFee

        if calculationResult <= 0 {
            return createNoRefundResult(data, reason: "計算結果がマイナスまたは0円のため払戻不可")
        }

        let detail = RefundCalculationDetail(
            calculationMethod: .monthlyCalculation,
            usedDays: data.elapsedDays,
            usedMonths: data.usedMonths,
            appliedRule: "月単位の通常計算",
            calculationSteps: createCalculationSteps(data, usedFare: usedFare, refundAmount: calculationResult)
        )

        let result = RefundResult(
            refundAmount: calculationResult,
            usedAmount: usedFare,
            processingFee: data.processingFee,
            calculationDetails: "\(data.passType.description): 使用\(data.usedMonths)ヶ月、使用分運賃\(usedFare)円"
        )

        return (result, detail)
    }

    // MARK: - 使用分運賃計算

    private func calculateUsedFare(_ data: RefundData) -> Int {
        switch data.passType {
        case .oneMonth:
            return data.purchasePrice // 実質的に使用されない
        case .threeMonths:
            return calculateThreeMonthUsedFare(data)
        case .sixMonths:
            return calculateSixMonthUsedFare(data)
        }
    }

    private func calculateThreeMonthUsedFare(_ data: RefundData) -> Int {
        if data.usedMonths <= 2 {
            return data.oneMonthFare * data.usedMonths
        } else {
            // 3ヶ月以上使用の場合は購入価格 + 追加月数
            let additionalMonths = data.usedMonths - 3
            return data.purchasePrice + (data.oneMonthFare * additionalMonths)
        }
    }

    private func calculateSixMonthUsedFare(_ data: RefundData) -> Int {
        guard let threeMonthFare = data.threeMonthFare else {
            fatalError("6ヶ月定期の計算には3ヶ月定期運賃が必要です")
        }

        if data.usedMonths <= 2 {
            return data.oneMonthFare * data.usedMonths
        } else {
            // 3ヶ月以上使用の場合は3ヶ月定期運賃 + 追加月数
            let additionalMonths = data.usedMonths - 3
            return threeMonthFare + (data.oneMonthFare * additionalMonths)
        }
    }

    // MARK: - ヘルパーメソッド

    private func createNoRefundResult(_ data: RefundData, reason: String) -> (RefundResult, RefundCalculationDetail) {
        let detail = RefundCalculationDetail(
            calculationMethod: .noRefund,
            usedDays: data.elapsedDays,
            usedMonths: data.usedMonths,
            appliedRule: reason,
            calculationSteps: []
        )

        let result = RefundResult(
            refundAmount: 0,
            usedAmount: 0,
            processingFee: data.processingFee,
            calculationDetails: reason
        )

        return (result, detail)
    }

    private func createCalculationSteps(_ data: RefundData, usedFare: Int, refundAmount: Int) -> [String] {
        var steps: [String] = []

        // 使用分運賃の計算詳細
        if data.usedMonths <= 2 {
            steps.append("使用分運賃 = \(data.oneMonthFare)円 × \(data.usedMonths)ヶ月 = \(usedFare)円")
        } else {
            switch data.passType {
            case .threeMonths:
                let additional = usedFare - data.purchasePrice
                steps.append("使用分運賃 = \(data.purchasePrice)円(3ヶ月分) + \(additional)円(追加分) = \(usedFare)円")
            case .sixMonths:
                let threeMonth = data.threeMonthFare ?? 0
                let additional = usedFare - threeMonth
                steps.append("使用分運賃 = \(threeMonth)円(3ヶ月分) + \(additional)円(追加分) = \(usedFare)円")
            default:
                break
            }
        }

        // 最終計算
        steps.append("払戻額 = \(data.purchasePrice)円 - \(usedFare)円 - \(data.processingFee)円 = \(refundAmount)円")

        return steps
    }
}

// MARK: - ログ出力

class RefundCalculationLogger {
    private var isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func logCalculation(_ data: RefundData, result: RefundResult, detail: RefundCalculationDetail) {
        guard isEnabled else { return }

        print("=== \(data.passType.description)の払い戻し計算 ===")
        print()
        logBasicInfo(data)
        logCalculationDetail(detail)
        logResult(result)
        print()
    }

    func logError(_ error: RefundDataValidator.ValidationError) {
        guard isEnabled else { return }
        print("❌ エラー: \(error.message)")
        print()
    }

    private func logBasicInfo(_ data: RefundData) {
        print("✅ 基本情報")
        print("   定期券種別: \(data.passType.description)")
        print("   購入価格: \(data.purchasePrice)円")
        print("   有効期間: \(formatDate(data.startDate)) ～ \(formatDate(data.endDate))")
        print("   払戻日: \(formatDate(data.refundDate))")
        print("   使用日数: \(data.elapsedDays)日")
        if data.usedMonths > 0 {
            print("   使用月数: \(data.usedMonths)ヶ月")
        }
        print()
    }

    private func logCalculationDetail(_ detail: RefundCalculationDetail) {
        print("📊 計算詳細")
        print("   適用ルール: \(detail.appliedRule)")

        if !detail.calculationSteps.isEmpty {
            print("   計算ステップ:")
            for step in detail.calculationSteps {
                print("     • \(step)")
            }
        }
        print()
    }

    private func logResult(_ result: RefundResult) {
        if result.refundAmount > 0 {
            print("✅ 計算結果")
            print("   最終払戻額: \(result.refundAmount)円")
        } else {
            print("❌ 払戻不可")
            print("   理由: \(result.calculationDetails)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

// MARK: - 統合クラス

class RegularRefundCalculator {
    private let validator = RefundDataValidator()
    private let engine = RefundCalculationEngine()
    private let logger: RefundCalculationLogger

    init(enableLogging: Bool = true) {
        self.logger = RefundCalculationLogger(isEnabled: enableLogging)
    }

    /// 通常払戻計算のメインエントリーポイント
    func calculate(data: RefundData) -> RefundResult {
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
    func calculateSilently(data: RefundData) -> RefundResult {
        let originalCalculator = RegularRefundCalculator(enableLogging: false)
        return originalCalculator.calculate(data: data)
    }
}
