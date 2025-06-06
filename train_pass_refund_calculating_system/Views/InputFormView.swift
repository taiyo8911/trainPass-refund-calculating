//
//  InputFormView.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/06.
//

import SwiftUI

// MARK: - 入力フォームセクション
struct CompactInputFormSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(spacing: 12) {
            // 計算方式選択
            VStack(alignment: .leading, spacing: 4) {
                Text("計算方式")
                    .font(.caption)
                    .fontWeight(.medium)

                Picker("計算方式", selection: $calculationState.calculationType) {
                    ForEach(RefundCalculationType.allCases, id: \.self) { type in
                        Text(type.description).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: calculationState.calculationType) { _, _ in
                    calculationState.resetResult()
                }
            }

            // 定期券種別選択
            VStack(alignment: .leading, spacing: 4) {
                Text("定期券種別")
                    .font(.caption)
                    .fontWeight(.medium)

                Picker("種別", selection: $calculationState.passType) {
                    ForEach(PassType.allCases, id: \.self) { type in
                        Text(type.rawValue == 1 ? "1ヶ月" : type.rawValue == 3 ? "3ヶ月" : "6ヶ月").tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: calculationState.passType) { _, _ in
                    calculationState.resetResult()
                }
            }

            // 日付入力（縦並び）
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("開始日")
                        .font(.caption)
                        .fontWeight(.medium)
                    HStack {
                        DatePicker("", selection: $calculationState.startDate, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            .onChange(of: calculationState.startDate) { _, _ in
                                calculationState.resetResult()
                            }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("払戻日")
                        .font(.caption)
                        .fontWeight(.medium)
                    HStack {
                        DatePicker("", selection: $calculationState.refundDate, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            .onChange(of: calculationState.refundDate) { _, _ in
                                calculationState.resetResult()
                            }
                        Spacer()
                    }
                }
            }

            // 金額入力
            CompactPriceInputSection(calculationState: calculationState)

            // バリデーションエラー表示
            if !calculationState.validationErrors.isEmpty {
                CompactErrorSection(errors: calculationState.validationErrors)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
}

// MARK: - 金額入力セクション
struct CompactPriceInputSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(spacing: 8) {
            // 定期券購入価格（常に表示）
            CompactPriceField(
                title: "定期券購入価格",
                value: $calculationState.purchasePrice,
                placeholder: "定期券購入価格"
            ) {
                calculationState.resetResult()
            }

            // 1ヶ月定期運賃（常に表示）
            CompactPriceField(
                title: "1ヶ月定期運賃",
                value: $calculationState.oneMonthFare,
                placeholder: "1ヶ月運賃"
            ) {
                calculationState.resetResult()
            }

            // 片道普通運賃（通常払戻のみ）
            if calculationState.needsOneWayFare {
                CompactPriceField(
                    title: "片道普通運賃",
                    value: $calculationState.oneWayFare,
                    placeholder: "片道運賃"
                ) {
                    calculationState.resetResult()
                }
            }

            // 3ヶ月定期運賃（6ヶ月定期のみ）
            if calculationState.needsThreeMonthFare {
                CompactPriceField(
                    title: "3ヶ月定期運賃",
                    value: $calculationState.threeMonthFare,
                    placeholder: "3ヶ月運賃"
                ) {
                    calculationState.resetResult()
                }
            }
        }
    }
}

// MARK: - 金額入力フィールド
struct CompactPriceField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            TextField(placeholder, text: $value)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.subheadline)
                .onChange(of: value) { _, _ in
                    onChange()
                }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - エラーセクション
struct CompactErrorSection: View {
    let errors: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("入力エラー")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            ForEach(errors, id: \.self) { error in
                Text("• \(error)")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - プレビュー
#Preview {
    CompactInputFormSection(calculationState: RefundCalculationState())
}
