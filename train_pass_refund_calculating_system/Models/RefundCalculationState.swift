//
//  RefundCalculationState.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/05.
//

import Foundation
import SwiftUI

@Observable
class RefundCalculationState {
    // MARK: - UI状態
    var calculationType: RefundCalculationType = .regular
    var showResultModal: Bool = false  // 結果モーダル表示フラグ
    var showPDFSheet: Bool = false
    var isCalculating: Bool = false

    // MARK: - 入力データ
    var startDate: Date = Date()
    var refundDate: Date = Date()
    var passType: PassType = .oneMonth
    var purchasePrice: String = ""
    var oneWayFare: String = ""      // 通常払戻のみ
    var oneMonthFare: String = ""
    var threeMonthFare: String = ""  // 6ヶ月定期の場合のみ

    // MARK: - 計算結果
    var result: RefundResult?
    var validationErrors: [String] = []

    // MARK: - 計算機インスタンス
    private let regularCalculator = RegularRefundCalculator(enableLogging: false)
    private let sectionChangeCalculator = SectionChangeRefundCalculator(enableLogging: false)

    // MARK: - 初期化
    init() {
        resetToDefaults()
    }

    // MARK: - バリデーション（修正：統一されたエラーハンドリングを使用）
    func validateInput() -> Bool {
        let result = validateInputWithUnifiedErrors()

        // 統一されたエラーメッセージに変換
        validationErrors = UserMessageConverter.convertToUserMessages(result.errors)

        // エラーログの出力
        if !result.isValid {
            ErrorHandler.logErrors(result.errors, context: "入力バリデーション")
        }

        return result.isValid
    }

    // 従来のバリデーションメソッドは削除し、統一版を使用

    // MARK: - 計算実行
    func performCalculation() {
        guard validateInput() else { return }

        isCalculating = true

        // 少し遅延を加えてUIの応答性を向上
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.executeCalculation()
            self.isCalculating = false
            self.showResultModal = true  // 計算完了後モーダル表示
        }
    }

    private func executeCalculation() {
        switch calculationType {
        case .regular:
            calculateRegularRefund()
        case .sectionChange:
            calculateSectionChangeRefund()
        }
    }

    private func calculateRegularRefund() {
        // 修正：安全な型変換を使用
        let purchasePriceResult = ErrorHandler.safeIntConversion(self.purchasePrice, fieldName: "購入価格")
        let oneWayFareResult = ErrorHandler.safeIntConversion(self.oneWayFare, fieldName: "片道普通運賃")
        let oneMonthFareResult = ErrorHandler.safeIntConversion(self.oneMonthFare, fieldName: "1ヶ月定期運賃")

        guard case .success(let purchasePrice) = purchasePriceResult,
              case .success(let oneWayFare) = oneWayFareResult,
              case .success(let oneMonthFare) = oneMonthFareResult else {
            EnhancedLogger.log(.calculationFailed("通常払戻の入力値変換に失敗"), context: "calculateRegularRefund")
            return
        }

        let threeMonthFare: Int?
        if passType == .sixMonths {
            let threeMonthFareResult = ErrorHandler.safeIntConversion(self.threeMonthFare, fieldName: "3ヶ月定期運賃")
            guard case .success(let value) = threeMonthFareResult else {
                EnhancedLogger.log(.calculationFailed("3ヶ月定期運賃の変換に失敗"), context: "calculateRegularRefund")
                return
            }
            threeMonthFare = value
        } else {
            threeMonthFare = nil
        }

        let refundData = RefundData(
            startDate: startDate,
            passType: passType,
            purchasePrice: purchasePrice,
            refundDate: refundDate,
            oneWayFare: oneWayFare,
            oneMonthFare: oneMonthFare,
            threeMonthFare: threeMonthFare
        )

        result = regularCalculator.calculateSilently(data: refundData)
    }

    private func calculateSectionChangeRefund() {
        // 修正：安全な型変換を使用
        let purchasePriceResult = ErrorHandler.safeIntConversion(self.purchasePrice, fieldName: "購入価格")

        guard case .success(let purchasePrice) = purchasePriceResult else {
            EnhancedLogger.log(.calculationFailed("区間変更払戻の入力値変換に失敗"), context: "calculateSectionChangeRefund")
            return
        }

        // 修正：区間変更払戻では購入価格のみで計算
        let refundData = SectionChangeRefundData(
            startDate: startDate,
            passType: passType,
            purchasePrice: purchasePrice,
            refundDate: refundDate
        )

        result = sectionChangeCalculator.calculateSilently(data: refundData)
    }

    // MARK: - ユーティリティ
    func resetToDefaults() {
        calculationType = .regular
        showResultModal = false  // モーダル状態もリセット
        showPDFSheet = false
        isCalculating = false

        startDate = Date()
        refundDate = Date()
        passType = .oneMonth
        purchasePrice = ""
        oneWayFare = ""
        oneMonthFare = ""
        threeMonthFare = ""

        result = nil
        validationErrors.removeAll()
    }

    func resetResult() {
        showResultModal = false  // モーダルを閉じる
        result = nil
        validationErrors.removeAll()
    }

    func closeResultModal() {
        showResultModal = false
    }

    // MARK: - 表示用プロパティ（修正：安全な型変換を使用）
    var canCalculate: Bool {
        if isCalculating {
            return false
        }

        // 購入価格の安全な検証
        guard case .success = ErrorHandler.safeIntConversion(purchasePrice, fieldName: "購入価格") else {
            return false
        }

        // 通常払戻の場合：片道運賃と1ヶ月定期運賃が必要
        if calculationType == .regular {
            guard case .success = ErrorHandler.safeIntConversion(oneWayFare, fieldName: "片道普通運賃"),
                  case .success = ErrorHandler.safeIntConversion(oneMonthFare, fieldName: "1ヶ月定期運賃") else {
                return false
            }

            // 6ヶ月定期の場合は3ヶ月定期運賃も必要
            if passType == .sixMonths {
                guard case .success = ErrorHandler.safeIntConversion(threeMonthFare, fieldName: "3ヶ月定期運賃") else {
                    return false
                }
            }
        }

        // 区間変更払戻の場合：購入価格のみで計算可能
        return true
    }

    var needsThreeMonthFare: Bool {
        // 通常払戻で6ヶ月定期の場合のみ必要
        return calculationType == .regular && passType == .sixMonths
    }

    var needsOneWayFare: Bool {
        // 通常払戻の場合のみ必要
        return calculationType == .regular
    }

    var needsOneMonthFare: Bool {
        // 通常払戻の場合のみ必要
        return calculationType == .regular
    }
}
