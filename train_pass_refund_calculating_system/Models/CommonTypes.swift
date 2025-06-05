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
