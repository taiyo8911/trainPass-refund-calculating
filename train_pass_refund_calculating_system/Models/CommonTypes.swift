//
//  CommonTypes.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/05.
//

import Foundation

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

/// 払戻計算方式
enum RefundCalculationType: String, CaseIterable {
    case regular = "regular"
    case sectionChange = "sectionChange"

    var description: String {
        switch self {
        case .regular: return "通常払戻"
        case .sectionChange: return "区間変更払戻"
        }
    }
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

        // 固定値（修正：定数クラスを使用）
        self.processingFee = CalculationConstants.processingFee

        // 往復普通運賃を計算
        self.roundTripFare = oneWayFare * 2

        // カレンダーインスタンス
        let calendar = Calendar.current

        // 日付を正規化（時刻の影響を排除）
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedRefundDate = calendar.startOfDay(for: refundDate)

        // 終了日を計算（修正：共通ヘルパーを使用）
        self.endDate = CalculationHelpers.calculateEndDate(startDate: normalizedStartDate, passType: passType)

        // 使用日数を計算（修正：共通ヘルパーを使用）
        self.elapsedDays = CalculationHelpers.calculateElapsedDays(from: normalizedStartDate, to: normalizedRefundDate)

        // 残存日数を計算
        let remainingComponents = calendar.dateComponents([.day], from: normalizedRefundDate, to: self.endDate)
        self.remainingDays = remainingComponents.day ?? 0

        // 残存月数を計算
        let remainingMonthComponents = calendar.dateComponents([.month], from: normalizedRefundDate, to: self.endDate)
        self.remainingMonths = remainingMonthComponents.month ?? 0

        // 使用月数を計算（修正：月の区切りベース）
        self.usedMonths = Self.calculateUsedMonths(
            startDate: normalizedStartDate,
            refundDate: normalizedRefundDate,
            calendar: calendar
        )
    }

    /// 使用月数を計算（月の区切りベース）
    /// 修正後の仕様：
    /// - 7日以内：日数計算を使用（0ヶ月扱い）
    /// - 8日目以降：月の区切りで計算
    /// - 例：6月5日開始の場合
    ///   - 6月5日〜7月4日：1ヶ月目
    ///   - 7月5日〜8月4日：2ヶ月目
    private static func calculateUsedMonths(startDate: Date, refundDate: Date, calendar: Calendar) -> Int {
        // 経過日数を計算（修正：共通ヘルパーを使用）
        let elapsedDays = CalculationHelpers.calculateElapsedDays(from: startDate, to: refundDate)

        // 7日以内の場合は0ヶ月扱い（日数計算を使用）
        if elapsedDays <= CalculationConstants.withinSevenDaysThreshold {
            return 0
        }

        // 8日目以降は月の区切りで計算
        // 開始日から月単位で区切りを作って、払戻日がどの区切りに属するかを判定
        var currentPeriodStart = startDate
        var monthCount = 0

        while true {
            monthCount += 1

            // 次の月の同日を計算
            guard let nextPeriodStart = calendar.date(byAdding: .month, value: 1, to: currentPeriodStart) else {
                break
            }

            // 払戻日が現在の期間内（currentPeriodStart <= refundDate < nextPeriodStart）かチェック
            if refundDate < nextPeriodStart {
                return monthCount
            }

            currentPeriodStart = nextPeriodStart
        }

        return monthCount
    }
}

/// 区間変更払い戻し計算専用データ（修正版）
/// 修正内容：
/// - 購入価格のみから日割運賃を計算（1ヶ月・3ヶ月定期運賃は不要）
/// - 共通ヘルパー関数を使用して計算の一貫性を確保
struct SectionChangeRefundData {
    // 基本入力データ
    let startDate: Date          // 開始日
    let passType: PassType       // 定期券種別
    let purchasePrice: Int       // 発売額
    let refundDate: Date         // 払戻日

    // 計算用データ（自動計算される）
    let elapsedDays: Int         // 経過日数（開始日含む）
    let usedJun: Int            // 使用旬数
    let dailyFare: Int          // 日割運賃
    let processingFee: Int      // 払戻手数料（固定220円）

    /// イニシャライザ：基本データから計算用データを自動生成
    /// 修正内容：
    /// - 購入価格のみから日割運賃を計算（定期運賃入力不要）
    /// - 共通ヘルパー関数とConstants使用で計算の統一性を確保
    /// - 1円未満切り上げのロジックを共通化
    init(startDate: Date, passType: PassType, purchasePrice: Int, refundDate: Date) {
        // 基本データ
        self.startDate = startDate
        self.passType = passType
        self.purchasePrice = purchasePrice
        self.refundDate = refundDate

        // 固定値（修正：定数クラスを使用）
        self.processingFee = CalculationConstants.processingFee

        // 経過日数を計算（修正：共通ヘルパーを使用）
        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedRefundDate = calendar.startOfDay(for: refundDate)

        self.elapsedDays = CalculationHelpers.calculateElapsedDays(from: normalizedStartDate, to: normalizedRefundDate)

        // 使用旬数を計算（修正：共通ヘルパーを使用）
        self.usedJun = CalculationHelpers.calculateJun(from: self.elapsedDays)

        // 日割運賃を計算（購入価格ベース、修正：共通ヘルパーと定数を使用）
        let baseDays = CalculationConstants.baseDaysFor(passType)
        self.dailyFare = CalculationHelpers.calculateDailyFare(amount: purchasePrice, days: baseDays)
    }
}

// MARK: - 拡張メソッド

extension Int {
    /// カンマ区切りの文字列を返す
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}
