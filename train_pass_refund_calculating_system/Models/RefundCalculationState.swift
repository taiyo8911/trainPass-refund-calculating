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
    var showResult: Bool = false
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
    
    // MARK: - バリデーション
    func validateInput() -> Bool {
        validationErrors.removeAll()
        
        // 共通バリデーション
        validateDates()
        validatePrices()
        validateTypeSpecificFields()
        
        return validationErrors.isEmpty
    }
    
    private func validateDates() {
        if refundDate < startDate {
            validationErrors.append("払戻日は開始日以降である必要があります")
        }
    }
    
    private func validatePrices() {
        if purchasePrice.isEmpty || Int(purchasePrice) == nil || Int(purchasePrice)! <= 0 {
            validationErrors.append("購入価格を正しく入力してください")
        }
        
        if oneMonthFare.isEmpty || Int(oneMonthFare) == nil || Int(oneMonthFare)! <= 0 {
            validationErrors.append("1ヶ月定期運賃を正しく入力してください")
        }
        
        // 通常払戻の場合は片道運賃が必要
        if calculationType == .regular {
            if oneWayFare.isEmpty || Int(oneWayFare) == nil || Int(oneWayFare)! <= 0 {
                validationErrors.append("片道普通運賃を正しく入力してください")
            }
        }
        
        // 6ヶ月定期の場合は3ヶ月定期運賃が必要
        if passType == .sixMonths {
            if threeMonthFare.isEmpty || Int(threeMonthFare) == nil || Int(threeMonthFare)! <= 0 {
                validationErrors.append("3ヶ月定期運賃を正しく入力してください")
            }
        }
    }
    
    private func validateTypeSpecificFields() {
        // 通常払戻の場合、払戻日が定期券有効期限内かチェック
        if calculationType == .regular {
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
            
            if refundDate > calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate {
                validationErrors.append("払戻日は定期券有効期限内である必要があります")
            }
        }
    }
    
    // MARK: - 計算実行
    func performCalculation() {
        guard validateInput() else { return }
        
        isCalculating = true
        
        // 少し遅延を加えてUIの応答性を向上
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.executeCalculation()
            self.isCalculating = false
            self.showResult = true
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
        guard let purchasePrice = Int(self.purchasePrice),
              let oneWayFare = Int(self.oneWayFare),
              let oneMonthFare = Int(self.oneMonthFare) else {
            return
        }
        
        let threeMonthFare = passType == .sixMonths ? Int(self.threeMonthFare) : nil
        
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
        guard let purchasePrice = Int(self.purchasePrice),
              let oneMonthFare = Int(self.oneMonthFare) else {
            return
        }
        
        let threeMonthFare = (passType == .threeMonths || passType == .sixMonths) ? Int(self.threeMonthFare) : nil
        
        let refundData = SectionChangeRefundData(
            startDate: startDate,
            passType: passType,
            purchasePrice: purchasePrice,
            refundDate: refundDate,
            oneMonthFare: oneMonthFare,
            threeMonthFare: threeMonthFare
        )
        
        result = sectionChangeCalculator.calculateSilently(data: refundData)
    }
    
    // MARK: - ユーティリティ
    func resetToDefaults() {
        calculationType = .regular
        showResult = false
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
        showResult = false
        result = nil
        validationErrors.removeAll()
    }
    
    // MARK: - 表示用プロパティ
    var canCalculate: Bool {
        !isCalculating && !purchasePrice.isEmpty && !oneMonthFare.isEmpty &&
        (calculationType == .sectionChange || !oneWayFare.isEmpty) &&
        (passType != .sixMonths || !threeMonthFare.isEmpty)
    }
    
    var needsThreeMonthFare: Bool {
        passType == .sixMonths
    }
    
    var needsOneWayFare: Bool {
        calculationType == .regular
    }
}
