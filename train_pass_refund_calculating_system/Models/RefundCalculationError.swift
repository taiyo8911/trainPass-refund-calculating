//
//  RefundCalculationError.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/09.
//

import Foundation

// MARK: - 統一されたエラー処理

/// アプリケーション全体で使用するエラー種別
enum RefundCalculationError: Error {
    // バリデーションエラー
    case invalidDate(String)
    case invalidAmount(String)
    case missingRequiredField(String)
    case dateRangeError(String)
    
    // 計算エラー
    case calculationFailed(String)
    case missingData(String)
    case unsupportedOperation(String)
    
    // システムエラー
    case fileOperationFailed(String)
    case networkError(String)
    case unknownError(String)
    
    /// エラーメッセージ（統一されたフォーマット）
    var localizedDescription: String {
        switch self {
        case .invalidDate(let details):
            return "【日付エラー】\(details)"
        case .invalidAmount(let details):
            return "【金額エラー】\(details)"
        case .missingRequiredField(let details):
            return "【入力エラー】\(details)"
        case .dateRangeError(let details):
            return "【期間エラー】\(details)"
        case .calculationFailed(let details):
            return "【計算エラー】\(details)"
        case .missingData(let details):
            return "【データエラー】\(details)"
        case .unsupportedOperation(let details):
            return "【操作エラー】\(details)"
        case .fileOperationFailed(let details):
            return "【ファイルエラー】\(details)"
        case .networkError(let details):
            return "【ネットワークエラー】\(details)"
        case .unknownError(let details):
            return "【システムエラー】\(details)"
        }
    }
    
    /// エラーコード（ログ出力用）
    var errorCode: String {
        switch self {
        case .invalidDate:
            return "E001"
        case .invalidAmount:
            return "E002"
        case .missingRequiredField:
            return "E003"
        case .dateRangeError:
            return "E004"
        case .calculationFailed:
            return "E101"
        case .missingData:
            return "E102"
        case .unsupportedOperation:
            return "E103"
        case .fileOperationFailed:
            return "E201"
        case .networkError:
            return "E202"
        case .unknownError:
            return "E999"
        }
    }
}

// MARK: - バリデーション結果

/// バリデーション結果を表現する型
struct ValidationResult {
    let isValid: Bool
    let errors: [RefundCalculationError]
    
    /// 成功時のインスタンス
    static let success = ValidationResult(isValid: true, errors: [])
    
    /// 失敗時のインスタンス生成
    static func failure(_ errors: [RefundCalculationError]) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors)
    }
    
    /// 単一エラーでの失敗インスタンス生成
    static func failure(_ error: RefundCalculationError) -> ValidationResult {
        return ValidationResult(isValid: false, errors: [error])
    }
    
    /// エラーメッセージのリストを取得
    var errorMessages: [String] {
        return errors.map { $0.localizedDescription }
    }
}

// MARK: - エラーハンドリングユーティリティ

/// エラーハンドリングの共通処理を提供
struct ErrorHandler {
    
    /// エラーログの出力
    /// - Parameters:
    ///   - error: エラー
    ///   - context: エラーが発生したコンテキスト
    static func logError(_ error: RefundCalculationError, context: String = "") {
        let timestamp = CommonDateFormatters.log.string(from: Date())
        let contextInfo = context.isEmpty ? "" : " [Context: \(context)]"
        print("[\(timestamp)] [\(error.errorCode)] \(error.localizedDescription)\(contextInfo)")
    }
    
    /// 複数エラーのログ出力
    /// - Parameters:
    ///   - errors: エラーのリスト
    ///   - context: エラーが発生したコンテキスト
    static func logErrors(_ errors: [RefundCalculationError], context: String = "") {
        for error in errors {
            logError(error, context: context)
        }
    }
    
    /// String→Int変換の安全な実行
    /// - Parameters:
    ///   - string: 変換対象の文字列
    ///   - fieldName: フィールド名（エラーメッセージ用）
    /// - Returns: 変換結果
    static func safeIntConversion(_ string: String, fieldName: String) -> Result<Int, RefundCalculationError> {
        guard !string.isEmpty else {
            return .failure(.missingRequiredField("\(fieldName)を入力してください"))
        }
        
        guard let value = Int(string) else {
            return .failure(.invalidAmount("\(fieldName)は数値で入力してください"))
        }
        
        guard value > 0 else {
            return .failure(.invalidAmount("\(fieldName)は正の数値で入力してください"))
        }
        
        return .success(value)
    }
    
    /// 日付範囲の検証
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    ///   - allowSameDay: 同日を許可するか
    /// - Returns: 検証結果
    static func validateDateRange(startDate: Date, endDate: Date, allowSameDay: Bool = true) -> ValidationResult {
        if allowSameDay {
            if startDate > endDate {
                return .failure(.dateRangeError("開始日は終了日以前である必要があります"))
            }
        } else {
            if startDate >= endDate {
                return .failure(.dateRangeError("開始日は終了日より前である必要があります"))
            }
        }
        
        return .success
    }
    
    /// 計算結果の妥当性検証
    /// - Parameter result: 計算結果
    /// - Returns: 検証結果
    static func validateCalculationResult(_ result: RefundResult) -> ValidationResult {
        var errors: [RefundCalculationError] = []
        
        if result.refundAmount < 0 {
            errors.append(.calculationFailed("払戻額が負の値になりました"))
        }
        
        if result.usedAmount < 0 {
            errors.append(.calculationFailed("使用分運賃が負の値になりました"))
        }
        
        if result.processingFee != CalculationConstants.processingFee {
            errors.append(.calculationFailed("手数料が正しく設定されていません"))
        }
        
        return errors.isEmpty ? .success : .failure(errors)
    }
}

// MARK: - 修正版バリデーター（統一されたエラーハンドリング）

/// 通常払戻用の統一バリデーター
struct UnifiedRefundDataValidator {
    
    /// 通常払戻データの包括的な検証
    /// - Parameter data: 検証対象データ
    /// - Returns: 検証結果
    static func validate(_ data: RefundData) -> ValidationResult {
        var errors: [RefundCalculationError] = []
        
        // 日付範囲検証
        let dateRangeResult = ErrorHandler.validateDateRange(
            startDate: data.startDate,
            endDate: data.refundDate
        )
        if !dateRangeResult.isValid {
            errors.append(contentsOf: dateRangeResult.errors)
        }
        
        // 払戻日が有効期限内かチェック
        if data.refundDate > data.endDate {
            errors.append(.dateRangeError("払戻日は定期券有効期限内である必要があります"))
        }
        
        // 6ヶ月定期の3ヶ月定期運賃チェック
        if data.passType == .sixMonths && data.threeMonthFare == nil {
            errors.append(.missingRequiredField("6ヶ月定期の払戻では3ヶ月定期運賃の入力が必要です"))
        }
        
        // 金額の妥当性チェック
        if data.purchasePrice <= 0 {
            errors.append(.invalidAmount("購入価格は正の値である必要があります"))
        }
        
        if data.oneWayFare <= 0 {
            errors.append(.invalidAmount("片道普通運賃は正の値である必要があります"))
        }
        
        if data.oneMonthFare <= 0 {
            errors.append(.invalidAmount("1ヶ月定期運賃は正の値である必要があります"))
        }
        
        if let threeMonthFare = data.threeMonthFare, threeMonthFare <= 0 {
            errors.append(.invalidAmount("3ヶ月定期運賃は正の値である必要があります"))
        }
        
        return errors.isEmpty ? .success : .failure(errors)
    }
}

/// 区間変更払戻用の統一バリデーター
struct UnifiedSectionChangeDataValidator {
    
    /// 区間変更払戻データの包括的な検証
    /// - Parameter data: 検証対象データ
    /// - Returns: 検証結果
    static func validate(_ data: SectionChangeRefundData) -> ValidationResult {
        var errors: [RefundCalculationError] = []
        
        // 日付範囲検証
        let dateRangeResult = ErrorHandler.validateDateRange(
            startDate: data.startDate,
            endDate: data.refundDate
        )
        if !dateRangeResult.isValid {
            errors.append(contentsOf: dateRangeResult.errors)
        }
        
        // 区間変更払戻の現実的な上限チェック（6ヶ月）
        let calendar = Calendar.current
        let maxRefundDate = calendar.date(byAdding: .month, value: 6, to: data.startDate) ?? data.startDate
        if data.refundDate > maxRefundDate {
            errors.append(.dateRangeError("払戻日が現実的な範囲（6ヶ月）を超えています"))
        }
        
        // 金額の妥当性チェック
        if data.purchasePrice <= 0 {
            errors.append(.invalidAmount("購入価格は正の値である必要があります"))
        }
        
        return errors.isEmpty ? .success : .failure(errors)
    }
}

// MARK: - 修正版計算状態のバリデーション

extension RefundCalculationState {
    
    /// 統一されたエラーハンドリングを使用した入力検証
    /// - Returns: 検証結果
    func validateInputWithUnifiedErrors() -> ValidationResult {
        var errors: [RefundCalculationError] = []
        
        // 日付検証
        let dateRangeResult = ErrorHandler.validateDateRange(
            startDate: startDate,
            endDate: refundDate
        )
        if !dateRangeResult.isValid {
            errors.append(contentsOf: dateRangeResult.errors)
        }
        
        // 購入価格検証
        let purchasePriceResult = ErrorHandler.safeIntConversion(purchasePrice, fieldName: "購入価格")
        if case .failure(let error) = purchasePriceResult {
            errors.append(error)
        }
        
        // 計算方式に応じた検証
        if calculationType == .regular {
            // 通常払戻の場合の検証
            validateRegularRefundFields(&errors)
        }
        // 区間変更払戻の場合は購入価格のみでOK
        
        return errors.isEmpty ? .success : .failure(errors)
    }
    
    private func validateRegularRefundFields(_ errors: inout [RefundCalculationError]) {
        // 1ヶ月定期運賃検証
        let oneMonthFareResult = ErrorHandler.safeIntConversion(oneMonthFare, fieldName: "1ヶ月定期運賃")
        if case .failure(let error) = oneMonthFareResult {
            errors.append(error)
        }
        
        // 片道普通運賃検証
        let oneWayFareResult = ErrorHandler.safeIntConversion(oneWayFare, fieldName: "片道普通運賃")
        if case .failure(let error) = oneWayFareResult {
            errors.append(error)
        }
        
        // 6ヶ月定期の場合の3ヶ月定期運賃検証
        if passType == .sixMonths {
            let threeMonthFareResult = ErrorHandler.safeIntConversion(threeMonthFare, fieldName: "3ヶ月定期運賃")
            if case .failure(let error) = threeMonthFareResult {
                errors.append(error)
            }
        }
        
        // 通常払戻の場合、払戻日が定期券有効期限内かチェック
        let calendar = Calendar.current
        let endDate: Date
        switch passType {
        case .oneMonth:
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .threeMonths:
            endDate = calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .sixMonths:
            endDate = calendar.date(byAdding: .month, value: 6, to: startDate) ?? startDate
        }
        
        let actualEndDate = calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        if refundDate > actualEndDate {
            errors.append(.dateRangeError("払戻日は定期券有効期限内である必要があります"))
        }
    }
}

// MARK: - ユーザー向けエラーメッセージ変換

/// エラーメッセージをユーザーフレンドリーに変換
struct UserMessageConverter {
    
    /// 技術的なエラーメッセージをユーザー向けに変換
    /// - Parameter error: 元のエラー
    /// - Returns: ユーザー向けメッセージ
    static func convertToUserMessage(_ error: RefundCalculationError) -> String {
        switch error {
        case .invalidDate(let details):
            return "日付の入力に問題があります。\(details)"
        case .invalidAmount(let details):
            return "金額の入力に問題があります。\(details)"
        case .missingRequiredField(let details):
            return "必須項目が入力されていません。\(details)"
        case .dateRangeError(let details):
            return "日付の設定に問題があります。\(details)"
        case .calculationFailed(let details):
            return "計算処理でエラーが発生しました。\(details)"
        case .missingData(let details):
            return "必要なデータが不足しています。\(details)"
        case .unsupportedOperation(let details):
            return "この操作は現在サポートされていません。\(details)"
        case .fileOperationFailed(let details):
            return "ファイルの処理でエラーが発生しました。\(details)"
        case .networkError(let details):
            return "ネットワークエラーが発生しました。\(details)"
        case .unknownError(let details):
            return "予期しないエラーが発生しました。\(details)"
        }
    }
    
    /// 複数エラーのユーザー向けメッセージ生成
    /// - Parameter errors: エラーのリスト
    /// - Returns: ユーザー向けメッセージのリスト
    static func convertToUserMessages(_ errors: [RefundCalculationError]) -> [String] {
        return errors.map { convertToUserMessage($0) }
    }
}

// MARK: - ログ記録強化

/// 強化されたログ記録機能
struct EnhancedLogger {
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        case critical = "CRITICAL"
    }
    
    /// ログレベル付きでエラーを記録
    /// - Parameters:
    ///   - error: エラー
    ///   - level: ログレベル
    ///   - context: コンテキスト情報
    ///   - function: 呼び出し元関数名
    ///   - file: 呼び出し元ファイル名
    ///   - line: 呼び出し元行番号
    static func log(
        _ error: RefundCalculationError,
        level: LogLevel = .error,
        context: String = "",
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        let timestamp = CommonDateFormatters.log.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let contextInfo = context.isEmpty ? "" : " [Context: \(context)]"
        
        print("[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line) \(function)] [\(error.errorCode)] \(error.localizedDescription)\(contextInfo)")
    }
    
    /// 情報ログの記録
    /// - Parameters:
    ///   - message: メッセージ
    ///   - context: コンテキスト
    static func info(_ message: String, context: String = "") {
        let timestamp = CommonDateFormatters.log.string(from: Date())
        let contextInfo = context.isEmpty ? "" : " [Context: \(context)]"
        print("[\(timestamp)] [INFO] \(message)\(contextInfo)")
    }
    
    /// デバッグログの記録
    /// - Parameters:
    ///   - message: メッセージ
    ///   - context: コンテキスト
    static func debug(_ message: String, context: String = "") {
        #if DEBUG
        let timestamp = CommonDateFormatters.log.string(from: Date())
        let contextInfo = context.isEmpty ? "" : " [Context: \(context)]"
        print("[\(timestamp)] [DEBUG] \(message)\(contextInfo)")
        #endif
    }
}
