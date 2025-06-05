import Foundation

// MARK: - データ構造

/// 定期券の種類
enum PassType: Int, CaseIterable {
    case oneMonth = 1
    case threeMonths = 3
    case sixMonths = 6

    var description: String {
        switch self {
        case .oneMonth: return "1ヶ月定期"
        case .threeMonths: return "3ヶ月定期"
        case .sixMonths: return "6ヶ月定期"
        }
    }
}

/// 払戻結果
struct RefundResult {
    let refundAmount: Int        // 最終払戻額
    let usedAmount: Int          // 使用分運賃
    let processingFee: Int       // 手数料
    let calculationDetails: String // 計算詳細
}

/// 通常払戻計算用データ
struct RefundData {
    let startDate: Date          // 開始日
    let passType: PassType       // 定期券種別
    let purchasePrice: Int       // 発売額
    let refundDate: Date         // 払戻日
    let oneWayFare: Int          // 片道普通運賃
    let oneMonthFare: Int        // 1ヶ月定期運賃
    let threeMonthFare: Int?     // 3ヶ月定期運賃（6ヶ月定期で必要）

    // 計算用データ（自動計算される）
    let endDate: Date            // 終了日
    let elapsedDays: Int         // 使用日数（開始日含む）
    let remainingDays: Int       // 残存日数
    let remainingMonths: Int     // 残存月数
    let usedMonths: Int          // 使用月数
    let roundTripFare: Int       // 往復普通運賃（片道運賃×2）
    let processingFee: Int       // 払戻手数料（固定220円）

    /// イニシャライザ：基本データから計算用データを自動生成
    init(startDate: Date, passType: PassType, purchasePrice: Int, refundDate: Date, oneWayFare: Int, oneMonthFare: Int, threeMonthFare: Int?) {
        // 基本データ
        self.startDate = startDate
        self.passType = passType
        self.purchasePrice = purchasePrice
        self.refundDate = refundDate
        self.oneWayFare = oneWayFare
        self.oneMonthFare = oneMonthFare
        self.threeMonthFare = threeMonthFare

        // 固定値
        self.processingFee = 220

        // 往復普通運賃を計算
        self.roundTripFare = oneWayFare * 2

        // 終了日を計算（開始日から期間後の前日）
        let calendar = Calendar.current
        let tempEndDate: Date
        switch passType {
        case .oneMonth:
            tempEndDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .threeMonths:
            tempEndDate = calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .sixMonths:
            tempEndDate = calendar.date(byAdding: .month, value: 6, to: startDate) ?? startDate
        }
        self.endDate = calendar.date(byAdding: .day, value: -1, to: tempEndDate) ?? tempEndDate

        // 使用日数を計算（開始日を含む）
        let elapsedComponents = calendar.dateComponents([.day], from: startDate, to: refundDate)
        self.elapsedDays = (elapsedComponents.day ?? 0) + 1

        // 残存日数を計算
        let remainingComponents = calendar.dateComponents([.day], from: refundDate, to: self.endDate)
        self.remainingDays = remainingComponents.day ?? 0

        // 残存月数を計算
        let remainingMonthComponents = calendar.dateComponents([.month], from: refundDate, to: self.endDate)
        self.remainingMonths = remainingMonthComponents.month ?? 0

        // 使用月数を計算（開始日を含め、払戻日の月まで）
        let monthComponents = calendar.dateComponents([.month, .day], from: startDate, to: refundDate)
        let months = (monthComponents.month ?? 0) + 1 // 開始月を含めるため+1
        self.usedMonths = months
    }
}

// MARK: - 通常払戻計算ロジック

class RegularRefundCalculator {

    /// 通常払戻計算を実行（定期券種別に応じて適切な計算を選択）
    func calculate(data: RefundData) -> RefundResult {
        switch data.passType {
        case .oneMonth:
            return calculateOneMonthPass(data: data)
        case .threeMonths:
            return calculateThreeMonthPass(data: data)
        case .sixMonths:
            return calculateSixMonthPass(data: data)
        }
    }

    // MARK: - 1ヶ月定期の払い戻し計算

    private func calculateOneMonthPass(data: RefundData) -> RefundResult {
        print("=== 1ヶ月定期の払い戻し計算 ===")
        print()

        // 基本的なチェック
        if let error = validateInput(data: data) {
            print("❌ エラー: \(error)")
            return RefundResult(
                refundAmount: 0,
                usedAmount: 0,
                processingFee: data.processingFee,
                calculationDetails: "エラー: \(error)"
            )
        }

        print("✅ \(data.passType.description)")
        print("   購入価格: \(data.purchasePrice)円")
        print("   有効期間: \(formatDate(data.startDate)) ～ \(formatDate(data.endDate))")
        print("   払戻日: \(formatDate(data.refundDate))")
        print("   使用日数: \(data.elapsedDays)日")
        print()

        // 使用開始後7日以内の場合
        if data.elapsedDays <= 7 {
            // 7日以内の場合の払戻額の計算
            // 払戻額 = 購入価格 - (往復運賃 × 使用日数) - 手数料）
            return RefundResult(
                refundAmount: data.purchasePrice - (data.roundTripFare * data.elapsedDays) - data.processingFee,
                usedAmount: data.roundTripFare * data.elapsedDays,
                processingFee: data.processingFee,
                calculationDetails: "使用開始から7日以内のため、払戻額を計算しました"
            )
        }
        // 使用開始から7日を超えた場合
        else {
            return RefundResult(
                refundAmount: 0,
                usedAmount: data.purchasePrice,
                processingFee: data.processingFee,
                calculationDetails: "使用開始から7日を超えた場合、払戻額はありません"
            )
        }    }

    // MARK: - 3ヶ月定期の払い戻し計算

    private func calculateThreeMonthPass(data: RefundData) -> RefundResult {
        print("=== 3ヶ月定期の払い戻し計算 ===")
        print()

        // 基本的なチェック
        if let error = validateInput(data: data) {
            print("❌ エラー: \(error)")
            return RefundResult(
                refundAmount: 0,
                usedAmount: 0,
                processingFee: data.processingFee,
                calculationDetails: "エラー: \(error)"
            )
        }

        print("✅ \(data.passType.description)")
        print("   購入価格: \(data.purchasePrice)円")
        print("   有効期間: \(formatDate(data.startDate)) ～ \(formatDate(data.endDate))")
        print("   払戻日: \(formatDate(data.refundDate))")
        print("   使用日数: \(data.elapsedDays)日")

        // 7日以内の場合の注意
        if data.elapsedDays <= 7 {
            print("⚠️  使用開始から7日以内の払戻のため、計算方法が変わります")
        }
        print()

        // 残存期間の確認
        if data.remainingMonths < 1 {
            print("❌ \(data.usedMonths)ヶ月以上使用しているため払い戻しはありません")
            return RefundResult(
                refundAmount: 0,
                usedAmount: 0,
                processingFee: data.processingFee,
                calculationDetails: "残存期間が1ヶ月未満のため払い戻しはありません"
            )
        }

        print("   残存月数: \(data.remainingMonths)ヶ月、残存日数: \(data.remainingDays)日")
        print("   使用月数: \(data.usedMonths)ヶ月")
        print()

        // 使用済みの運賃を計算
        let usedFare = calculateThreeMonthUsedFare(data: data)
        print()

        // 最終的な払戻額を計算
        print("   計算式: 購入価格 - 使用月数定期運賃 - 手数料")
        print("   計算式: \(data.purchasePrice)円 - \(usedFare)円 - \(data.processingFee)円")
        let calculationResult = data.purchasePrice - usedFare - data.processingFee
        print("   計算結果: \(calculationResult)円")

        if calculationResult <= 0 {
            print("❌ 計算結果がマイナスまたは0円のため払戻額はありません")
            print()
            return RefundResult(
                refundAmount: 0,
                usedAmount: usedFare,
                processingFee: data.processingFee,
                calculationDetails: "計算結果がマイナスまたは0円のため払戻額はありません"
            )
        }

        print("   最終払戻額: \(calculationResult)円")
        print()

        return RefundResult(
            refundAmount: calculationResult,
            usedAmount: usedFare,
            processingFee: data.processingFee,
            calculationDetails: "3ヶ月定期: 使用\(data.usedMonths)ヶ月、使用分定期運賃\(usedFare)円"
        )
    }

    private func calculateThreeMonthUsedFare(data: RefundData) -> Int {
        if data.usedMonths <= 2 {
            // 1ヶ月または2ヶ月使用の場合
            let usedFare = data.oneMonthFare * data.usedMonths
            print("   1ヶ月の定期運賃： \(data.oneMonthFare)円")
            print("   \(data.usedMonths)ヶ月使用: \(data.oneMonthFare)円 × \(data.usedMonths) = \(usedFare)円")
            return usedFare
        } else {
            // 3ヶ月以上使用の場合
            var totalFare = 0

            // 最初の3ヶ月分は購入価格をそのまま使用
            totalFare = data.purchasePrice
            print("   3ヶ月の定期運賃： \(data.purchasePrice)円")
            print("   → 3ヶ月分: \(data.purchasePrice)円（購入価格をそのまま使用）")

            // 4ヶ月目以降は1ヶ月ずつ追加
            let additionalMonths = data.usedMonths - 3
            if additionalMonths > 0 {
                let additionalFare = data.oneMonthFare * additionalMonths
                totalFare += additionalFare
                print("   → 追加\(additionalMonths)ヶ月分: \(data.oneMonthFare)円 × \(additionalMonths) = \(additionalFare)円")
            }
            print("   → 使用分運賃合計: \(totalFare)円")
            return totalFare
        }
    }

    // MARK: - 6ヶ月定期の払い戻し計算

    private func calculateSixMonthPass(data: RefundData) -> RefundResult {
        print("=== 6ヶ月定期の払い戻し計算 ===")
        print()

        // 基本的なチェック
        if let error = validateInput(data: data) {
            print("❌ エラー: \(error)")
            return RefundResult(
                refundAmount: 0,
                usedAmount: 0,
                processingFee: data.processingFee,
                calculationDetails: "エラー: \(error)"
            )
        }

        print("✅ \(data.passType.description)")
        print("   購入価格: \(data.purchasePrice)円")
        print("   有効期間: \(formatDate(data.startDate)) ～ \(formatDate(data.endDate))")
        print("   払戻日: \(formatDate(data.refundDate))")

        if let threeMonthFare = data.threeMonthFare {
            print("   3ヶ月定期運賃: \(threeMonthFare)円")
        }
        print("   使用日数: \(data.elapsedDays)日")

        // 7日以内の場合の注意
        if data.elapsedDays <= 7 {
            print("⚠️  使用開始から7日以内の払戻のため、計算方法が変わります")
        }
        print()

        // 残存期間の確認
        print("   残存月数: \(data.remainingMonths)ヶ月、残存日数: \(data.remainingDays)日")
        if data.remainingMonths < 1 {
            print("❌ \(data.usedMonths)ヶ月以上使用しているため払い戻しはありません")
            return RefundResult(
                refundAmount: 0,
                usedAmount: 0,
                processingFee: data.processingFee,
                calculationDetails: "残存期間が1ヶ月未満のため払い戻しはありません"
            )
        }

        print("   使用月数: \(data.usedMonths)ヶ月")
        print()

        // 使用分運賃を計算
        let usedFare = calculateSixMonthUsedFare(data: data)
        print()

        // 最終的な払戻額を計算
        print("   計算式: 購入価格 - 使用分運賃 - 手数料")
        print("   計算式: \(data.purchasePrice)円 - \(usedFare)円 - \(data.processingFee)円")
        let calculationResult = data.purchasePrice - usedFare - data.processingFee
        print("   計算結果: \(calculationResult)円")

        if calculationResult <= 0 {
            print("❌ 計算結果がマイナスまたは0円のため払戻額はありません")
            print()
            return RefundResult(
                refundAmount: 0,
                usedAmount: usedFare,
                processingFee: data.processingFee,
                calculationDetails: "計算結果がマイナスまたは0円のため払戻額はありません"
            )
        }

        print("   最終払戻額: \(calculationResult)円")
        print()

        return RefundResult(
            refundAmount: calculationResult,
            usedAmount: usedFare,
            processingFee: data.processingFee,
            calculationDetails: "6ヶ月定期: 使用\(data.usedMonths)ヶ月、使用済み定期運賃\(usedFare)円"
        )
    }

    private func calculateSixMonthUsedFare(data: RefundData) -> Int {
        guard let threeMonthFare = data.threeMonthFare else {
            fatalError("6ヶ月定期の払戻には3ヶ月定期運賃が必要です")
        }

        if data.usedMonths <= 2 {
            // 1ヶ月または2ヶ月使用の場合
            let usedFare = data.oneMonthFare * data.usedMonths
            print("   1ヶ月の定期運賃： \(data.oneMonthFare)円")
            print("   → \(data.usedMonths)ヶ月使用: \(data.oneMonthFare)円 × \(data.usedMonths) = \(usedFare)円")
            return usedFare
        } else {
            // 3ヶ月以上使用の場合
            var totalFare = 0

            // 最初の3ヶ月分は3ヶ月定期運賃を使用
            totalFare = threeMonthFare
            print("   3ヶ月の定期運賃： \(threeMonthFare)円")
            print("   → 3ヶ月分: \(threeMonthFare)円（3ヶ月定期運賃を使用）")

            // 4ヶ月目以降は1ヶ月ずつ追加
            let additionalMonths = data.usedMonths - 3
            if additionalMonths > 0 {
                let additionalFare = data.oneMonthFare * additionalMonths
                totalFare += additionalFare
                print("   → 追加\(additionalMonths)ヶ月分: \(data.oneMonthFare)円 × \(additionalMonths) = \(additionalFare)円")
            }

            print("   → 使用分運賃合計: \(totalFare)円")
            return totalFare
        }
    }

    // MARK: - 共通メソッド

    /// 入力検証
    private func validateInput(data: RefundData) -> String? {
        if data.refundDate < data.startDate {
            return "払戻日は開始日以降である必要があります"
        }

        if data.refundDate > data.endDate {
            return "払戻日は終了日以前である必要があります"
        }

        // 6ヶ月定期の場合は3ヶ月定期運賃が必要
        if data.passType == .sixMonths && data.threeMonthFare == nil {
            return "6ヶ月定期の払戻では3ヶ月定期運賃の入力が必要です"
        }

        return nil
    }

    /// 日付を読みやすい形式でフォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}
