//
//  SectionChangeRefundCalculator.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/03.
//

import Foundation

// MARK: - 区間変更払い戻し計算（完全独立）
class SectionChangeRefundCalculator {
    /// 区間変更払い戻し計算専用データ
    struct SectionChangeRefundData {
        // 基本入力データ
        let startDate: Date          // 開始日
        let passType: PassType       // 定期券種別
        let purchasePrice: Int       // 発売額
        let refundDate: Date         // 払戻日
        let oneMonthFare: Int        // 1ヶ月定期運賃
        let threeMonthFare: Int?     // 3ヶ月定期運賃（3・6ヶ月定期で必要）

        // 計算用データ（自動計算される）
        let elapsedDays: Int         // 経過日数（開始日含む）
        let usedJun: Int            // 使用旬数
        let dailyFare: Int          // 日割運賃
        let processingFee: Int      // 払戻手数料（固定220円）

        /// イニシャライザ：基本データから計算用データを自動生成
        init(startDate: Date, passType: PassType, purchasePrice: Int, refundDate: Date, oneMonthFare: Int, threeMonthFare: Int?) {
            // 基本データ
            self.startDate = startDate
            self.passType = passType
            self.purchasePrice = purchasePrice
            self.refundDate = refundDate
            self.oneMonthFare = oneMonthFare
            self.threeMonthFare = threeMonthFare

            // 固定値
            self.processingFee = 220

            // 経過日数を計算（開始日を含む）
            let calendar = Calendar.current
            let elapsedComponents = calendar.dateComponents([.day], from: startDate, to: refundDate)
            self.elapsedDays = (elapsedComponents.day ?? 0) + 1

            // 使用旬数を計算（開始日から10日ずつ、端数は1旬）
            let totalDays = self.elapsedDays
            let fullJun = totalDays / 10
            let remainder = totalDays % 10
            self.usedJun = fullJun + (remainder > 0 ? 1 : 0)

            // 日割運賃を計算（1円未満切り上げ）
            let fare: Double
            switch passType {
            case .oneMonth:
                fare = Double(oneMonthFare) / 30.0 // 1ヶ月定期÷30日
            case .threeMonths:
                fare = Double(threeMonthFare ?? oneMonthFare) / 90.0 // 3ヶ月定期÷90日
            case .sixMonths:
                fare = Double(purchasePrice) / 180.0 // 6ヶ月定期÷180日
            }
            self.dailyFare = Int(ceil(fare)) // 1円未満切り上げ
        }
    }

    /// 区間変更払い戻し計算を実行
    func calculate(data: SectionChangeRefundData) -> RefundResult {
        // 入力検証
        if let error = validateInput(data: data) {
            return RefundResult(
                refundAmount: 0,
                usedAmount: 0,
                processingFee: data.processingFee,
                calculationDetails: error
                )
        }

        // 使用分運賃を計算
        let usedFare = data.usedJun * data.dailyFare * 10

        // 最終払戻額を計算
        let refundAmount = max(0, data.purchasePrice - usedFare - data.processingFee)

        let details = """
        【区間変更払い戻し計算】
        使用旬数: \(data.usedJun)旬
        日割運賃: \(data.dailyFare)円/日
        使用分運賃: \(usedFare)円 (\(data.usedJun)旬 × \(data.dailyFare)円 × 10)
        計算式: \(data.purchasePrice)円 - \(usedFare)円 - \(data.processingFee)円 = \(refundAmount)円
        """

        return RefundResult(
        refundAmount: refundAmount,
        usedAmount: usedFare,
        processingFee: data.processingFee,
        calculationDetails: details
        )
    }

    /// 入力検証
    private func validateInput(data: SectionChangeRefundData) -> String? {
        if data.refundDate < data.startDate {
            return "払戻日は開始日以降である必要があります"
        }

        // 区間変更払戻では終了日の概念がないため、現実的な上限をチェック
        let calendar = Calendar.current
        let maxRefundDate = calendar.date(byAdding: .month, value: 6, to: data.startDate) ?? data.startDate
        if data.refundDate > maxRefundDate {
            return "払戻日が現実的な範囲を超えています"
        }
        return nil
    }
}


// MARK: - 使用例

/// 使用例を示すクラス
class SectionChangeRefundDemo {
    func runDemo() {
        print("=== 区間変更払い戻し計算システム ===\n")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // ケース1: 正常な区間変更払い戻し（37日使用、4旬）
        print("【ケース1: 正常な区間変更払い戻し】")
        let sectionChangeData1 = SectionChangeRefundCalculator.SectionChangeRefundData(
        startDate: dateFormatter.date(from: "2025-02-07")!,
        passType: .threeMonths,
        purchasePrice: 45000,
        refundDate: dateFormatter.date(from: "2025-03-16")!, // 37日後
        oneMonthFare: 16000,
        threeMonthFare: 45000
        )
        executeCalculation(data: sectionChangeData1, dateFormatter: dateFormatter)

        // ケース2: 1ヶ月定期での区間変更（15日使用、2旬）
        print("【ケース2: 1ヶ月定期での区間変更】")
        let sectionChangeData2 = SectionChangeRefundCalculator.SectionChangeRefundData(
        startDate: dateFormatter.date(from: "2025-02-07")!,
        passType: .oneMonth,
        purchasePrice: 16000,
        refundDate: dateFormatter.date(from: "2025-02-21")!, // 15日後
        oneMonthFare: 16000,
        threeMonthFare: nil
        )
        executeCalculation(data: sectionChangeData2, dateFormatter: dateFormatter)

        // ケース3: 旬数計算の境界テスト（10日ちょうど、1旬）
        print("【ケース3: 旬数計算の境界テスト（10日ちょうど）】")
        let sectionChangeData3 = SectionChangeRefundCalculator.SectionChangeRefundData(
        startDate: dateFormatter.date(from: "2025-02-07")!,
        passType: .threeMonths,
        purchasePrice: 45000,
        refundDate: dateFormatter.date(from: "2025-02-16")!, // 10日後
        oneMonthFare: 16000,
        threeMonthFare: 45000
        )
        executeCalculation(data: sectionChangeData3, dateFormatter: dateFormatter)

        // ケース4: 旬数計算の境界テスト（11日、2旬）
        print("【ケース4: 旬数計算の境界テスト（11日）】")
        let sectionChangeData4 = SectionChangeRefundCalculator.SectionChangeRefundData(
        startDate: dateFormatter.date(from: "2025-02-07")!,
        passType: .threeMonths,
        purchasePrice: 45000,
        refundDate: dateFormatter.date(from: "2025-02-17")!, // 11日後
        oneMonthFare: 16000,
        threeMonthFare: 45000
        )
        executeCalculation(data: sectionChangeData4, dateFormatter: dateFormatter)

        // ケース5: 払戻日が開始日より前（エラー）
        print("【ケース5: 払戻日が開始日より前（エラー）】")
        let sectionChangeData5 = SectionChangeRefundCalculator.SectionChangeRefundData(
        startDate: dateFormatter.date(from: "2025-02-07")!,
        passType: .threeMonths,
        purchasePrice: 45000,
        refundDate: dateFormatter.date(from: "2025-02-05")!, // 開始日より前
        oneMonthFare: 16000,
        threeMonthFare: 45000
        )
        executeCalculation(data: sectionChangeData5, dateFormatter: dateFormatter)

        // ケース6: 使用分運賃が購入価格を上回る場合
        print("【ケース6: 使用分運賃が購入価格を上回る場合】")
        let sectionChangeData6 = SectionChangeRefundCalculator.SectionChangeRefundData(
        startDate: dateFormatter.date(from: "2025-02-07")!,
        passType: .oneMonth,
        purchasePrice: 10000, // 安い定期券
        refundDate: dateFormatter.date(from: "2025-02-28")!, // 長期間使用
        oneMonthFare: 16000,
        threeMonthFare: nil
        )
        executeCalculation(data: sectionChangeData6, dateFormatter: dateFormatter)
    }

    private func executeCalculation(data: SectionChangeRefundCalculator.SectionChangeRefundData, dateFormatter: DateFormatter) {
        print("定期券情報:")
        print("- 定期券の種類: \(data.passType.description)")
        print("- 定期券の値段: \(data.purchasePrice)円")
        print("- 開始日: \(dateFormatter.string(from: data.startDate))")
        print("- 終了日: 計算対象外（区間変更のため）")
        print()
        print("払戻情報:")
        print("- 払戻理由: 区間変更")
        print("- 払戻日: \(dateFormatter.string(from: data.refundDate))")
        print("- 使用日数: \(data.elapsedDays)日")
        print("- 使用旬数: \(data.usedJun)旬")
        print("- 日割運賃: \(data.dailyFare)円/日")
        print()

        let sectionChangeCalculator = SectionChangeRefundCalculator()
        let sectionChangeResult = sectionChangeCalculator.calculate(data: data)

        if sectionChangeResult.refundAmount > 0 {
            let sectionChangeUsedFare = sectionChangeResult.usedAmount
            print("【区間変更払い戻し計算】")
            print("- 計算式: \(data.purchasePrice)円 - \(sectionChangeUsedFare)円 - \(data.processingFee)円 = \(sectionChangeResult.refundAmount)円")
            print("- 最終払戻額: \(sectionChangeResult.refundAmount)円")
        } else {
        print("【エラー・払戻不可】")
        print("- 結果: \(sectionChangeResult.calculationDetails)")
        }
        print()
        print("---")
        print()
    }
}
