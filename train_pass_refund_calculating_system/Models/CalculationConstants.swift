//
//  CalculationConstants.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/09.
//


import Foundation

/// 定期券払戻計算で使用する定数を一元管理
struct CalculationConstants {
    
    // MARK: - 手数料
    
    /// 払戻手数料（円）
    static let processingFee: Int = 220
    
    // MARK: - 日数基準
    
    /// 1ヶ月定期の日割計算基準日数
    static let oneMonthDays: Int = 30
    
    /// 3ヶ月定期の日割計算基準日数
    static let threeMonthDays: Int = 90
    
    /// 6ヶ月定期の日割計算基準日数
    static let sixMonthDays: Int = 180
    
    // MARK: - 計算ルール
    
    /// 7日以内ルール適用の境界日数
    static let withinSevenDaysThreshold: Int = 7
    
    /// 旬数計算の基準日数（10日単位）
    static let junBaseDays: Int = 10
    
    // MARK: - ヘルパーメソッド
    
    /// 定期券種別に応じた日割計算基準日数を取得
    /// - Parameter passType: 定期券種別
    /// - Returns: 基準日数
    static func baseDaysFor(_ passType: PassType) -> Int {
        switch passType {
        case .oneMonth:
            return oneMonthDays
        case .threeMonths:
            return threeMonthDays
        case .sixMonths:
            return sixMonthDays
        }
    }
}

// MARK: - 日付フォーマッターの共通化

/// アプリ全体で使用する日付フォーマッターを一元管理
struct CommonDateFormatters {
    
    /// 標準的な日付表示用（yyyy年MM月dd日）
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    /// PDF用フッター日時表示（yyyy年MM月dd日 HH:mm）
    static let pdfFooter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    /// ログ出力用日時表示（yyyy-MM-dd HH:mm:ss）
    static let log: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    /// デバッグ・テスト用日付表示（yyyy-MM-dd）
    static let debug: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

// MARK: - 計算ヘルパー関数

/// 共通的な日付・期間計算を提供
struct CalculationHelpers {
    
    /// 経過日数を計算（開始日を含む）
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    /// - Returns: 経過日数
    static func calculateElapsedDays(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = calendar.startOfDay(for: endDate)
        
        let components = calendar.dateComponents([.day], from: normalizedStartDate, to: normalizedEndDate)
        return (components.day ?? 0) + 1 // 開始日を含むため+1
    }
    
    /// 定期券の終了日を計算
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - passType: 定期券種別
    /// - Returns: 終了日（有効期限の最終日）
    static func calculateEndDate(startDate: Date, passType: PassType) -> Date {
        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        
        let tempEndDate: Date
        switch passType {
        case .oneMonth:
            tempEndDate = calendar.date(byAdding: .month, value: 1, to: normalizedStartDate) ?? normalizedStartDate
        case .threeMonths:
            tempEndDate = calendar.date(byAdding: .month, value: 3, to: normalizedStartDate) ?? normalizedStartDate
        case .sixMonths:
            tempEndDate = calendar.date(byAdding: .month, value: 6, to: normalizedStartDate) ?? normalizedStartDate
        }
        
        // 終了日は期間後の前日
        return calendar.date(byAdding: .day, value: -1, to: tempEndDate) ?? tempEndDate
    }
    
    /// 旬数を計算（10日単位、端数は1旬扱い）
    /// - Parameter days: 日数
    /// - Returns: 旬数
    static func calculateJun(from days: Int) -> Int {
        let fullJun = days / CalculationConstants.junBaseDays
        let remainder = days % CalculationConstants.junBaseDays
        return fullJun + (remainder > 0 ? 1 : 0)
    }
    
    /// 日割運賃を計算（1円未満切り上げ）
    /// - Parameters:
    ///   - amount: 基準金額
    ///   - days: 日数
    /// - Returns: 日割運賃
    static func calculateDailyFare(amount: Int, days: Int) -> Int {
        let fare = Double(amount) / Double(days)
        return Int(ceil(fare)) // 1円未満切り上げ
    }
}
