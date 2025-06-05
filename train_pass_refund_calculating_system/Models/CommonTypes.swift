////
////  CommonTypes.swift
////  train_pass_refund_calculating_system
////
////  Created by Taiyo KOSHIBA on 2025/06/05.
////
//
//import Foundation
//
///// 定期券の種類
//enum PassType: Int, CaseIterable {
//    case oneMonth = 1
//    case threeMonths = 3
//    case sixMonths = 6
//
//    var description: String {
//        switch self {
//        case .oneMonth: return "1ヶ月定期"
//        case .threeMonths: return "3ヶ月定期"
//        case .sixMonths: return "6ヶ月定期"
//        }
//    }
//}
//
///// 払戻結果
//struct RefundResult {
//    let refundAmount: Int        // 最終払戻額
//    let usedAmount: Int          // 使用分運賃
//    let processingFee: Int       // 手数料
//    let calculationDetails: String // 計算詳細
//}
//
///// 払戻計算方式
//enum RefundCalculationType: String, CaseIterable {
//    case regular = "regular"
//    case sectionChange = "sectionChange"
//
//    var description: String {
//        switch self {
//        case .regular: return "通常払戻"
//        case .sectionChange: return "区間変更払戻"
//        }
//    }
//}
//
///// 通常払戻計算用データ
//struct RefundData {
//    let startDate: Date          // 開始日
//    let passType: PassType       // 定期券種別
//    let purchasePrice: Int       // 発売額
//    let refundDate: Date         // 払戻日
//    let oneWayFare: Int          // 片道普通運賃
//    let oneMonthFare: Int        // 1ヶ月定期運賃
//    let threeMonthFare: Int?     // 3ヶ月定期運賃（6ヶ月定期で必要）
//
//    // 計算用データ（自動計算される）
//    let endDate: Date            // 終了日
//    let elapsedDays: Int         // 使用日数（開始日含む）
//    let remainingDays: Int       // 残存日数
//    let remainingMonths: Int     // 残存月数
//    let usedMonths: Int          // 使用月数
//    let roundTripFare: Int       // 往復普通運賃（片道運賃×2）
//    let processingFee: Int       // 払戻手数料（固定220円）
//
//    /// イニシャライザ：基本データから計算用データを自動生成
//    init(startDate: Date, passType: PassType, purchasePrice: Int, refundDate: Date, oneWayFare: Int, oneMonthFare: Int, threeMonthFare: Int?) {
//        // 基本データ
//        self.startDate = startDate
//        self.passType = passType
//        self.purchasePrice = purchasePrice
//        self.refundDate = refundDate
//        self.oneWayFare = oneWayFare
//        self.oneMonthFare = oneMonthFare
//        self.threeMonthFare = threeMonthFare
//
//        // 固定値
//        self.processingFee = 220
//
//        // 往復普通運賃を計算
//        self.roundTripFare = oneWayFare * 2
//
//        // 終了日を計算（開始日から期間後の前日）
//        let calendar = Calendar.current
//        let tempEndDate: Date
//        switch passType {
//        case .oneMonth:
//            tempEndDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
//        case .threeMonths:
//            tempEndDate = calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
//        case .sixMonths:
//            tempEndDate = calendar.date(byAdding: .month, value: 6, to: startDate) ?? startDate
//        }
//        self.endDate = calendar.date(byAdding: .day, value: -1, to: tempEndDate) ?? tempEndDate
//
//        // 使用日数を計算（開始日を含む）
//        let elapsedComponents = calendar.dateComponents([.day], from: startDate, to: refundDate)
//        self.elapsedDays = (elapsedComponents.day ?? 0) + 1
//
//        // 残存日数を計算
//        let remainingComponents = calendar.dateComponents([.day], from: refundDate, to: self.endDate)
//        self.remainingDays = remainingComponents.day ?? 0
//
//        // 残存月数を計算
//        let remainingMonthComponents = calendar.dateComponents([.month], from: refundDate, to: self.endDate)
//        self.remainingMonths = remainingMonthComponents.month ?? 0
//
//        // 使用月数を計算（開始日を含め、払戻日の月まで）
//        let monthComponents = calendar.dateComponents([.month, .day], from: startDate, to: refundDate)
//        let months = (monthComponents.month ?? 0) + 1 // 開始月を含めるため+1
//        self.usedMonths = months
//    }
//}
//
///// 区間変更払い戻し計算専用データ
//struct SectionChangeRefundData {
//    // 基本入力データ
//    let startDate: Date          // 開始日
//    let passType: PassType       // 定期券種別
//    let purchasePrice: Int       // 発売額
//    let refundDate: Date         // 払戻日
//    let oneMonthFare: Int        // 1ヶ月定期運賃
//    let threeMonthFare: Int?     // 3ヶ月定期運賃（3・6ヶ月定期で必要）
//
//    // 計算用データ（自動計算される）
//    let elapsedDays: Int         // 経過日数（開始日含む）
//    let usedJun: Int            // 使用旬数
//    let dailyFare: Int          // 日割運賃
//    let processingFee: Int      // 払戻手数料（固定220円）
//
//    /// イニシャライザ：基本データから計算用データを自動生成
//    init(startDate: Date, passType: PassType, purchasePrice: Int, refundDate: Date, oneMonthFare: Int, threeMonthFare: Int?) {
//        // 基本データ
//        self.startDate = startDate
//        self.passType = passType
//        self.purchasePrice = purchasePrice
//        self.refundDate = refundDate
//        self.oneMonthFare = oneMonthFare
//        self.threeMonthFare = threeMonthFare
//
//        // 固定値
//        self.processingFee = 220
//
//        // 経過日数を計算（開始日を含む）
//        let calendar = Calendar.current
//        let elapsedComponents = calendar.dateComponents([.day], from: startDate, to: refundDate)
//        self.elapsedDays = (elapsedComponents.day ?? 0) + 1
//
//        // 使用旬数を計算（開始日から10日ずつ、端数は1旬）
//        let totalDays = self.elapsedDays
//        let fullJun = totalDays / 10
//        let remainder = totalDays % 10
//        self.usedJun = fullJun + (remainder > 0 ? 1 : 0)
//
//        // 日割運賃を計算（1円未満切り上げ）
//        let fare: Double
//        switch passType {
//        case .oneMonth:
//            fare = Double(oneMonthFare) / 30.0 // 1ヶ月定期÷30日
//        case .threeMonths:
//            fare = Double(threeMonthFare ?? oneMonthFare) / 90.0 // 3ヶ月定期÷90日
//        case .sixMonths:
//            fare = Double(purchasePrice) / 180.0 // 6ヶ月定期÷180日
//        }
//        self.dailyFare = Int(ceil(fare)) // 1円未満切り上げ
//    }
//}


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

        // 使用日数を計算（開始日を含む）- 時刻の影響を排除
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedRefundDate = calendar.startOfDay(for: refundDate)

        let elapsedComponents = calendar.dateComponents([.day], from: normalizedStartDate, to: normalizedRefundDate)
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

        // 経過日数を計算（開始日を含む）- 時刻の影響を排除
        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedRefundDate = calendar.startOfDay(for: refundDate)

        let elapsedComponents = calendar.dateComponents([.day], from: normalizedStartDate, to: normalizedRefundDate)
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
