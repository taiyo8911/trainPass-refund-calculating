//
//  PDFPreviewView.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/06.
//

import SwiftUI
import PDFKit

// MARK: - PDFプレビュー
struct PDFPreviewView: View {
    @Bindable var calculationState: RefundCalculationState
    @State private var pdfData: Data?
    @State private var isGeneratingPDF = false
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            VStack {
                if isGeneratingPDF {
                    // PDF生成中
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("PDFを生成中...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let pdfData = pdfData {
                    // PDFプレビュー
                    PDFPreview(data: pdfData)
                } else {
                    // エラー表示
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("PDFの生成に失敗しました")
                            .font(.headline)
                        Button("再試行") {
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("計算結果PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        calculationState.showPDFSheet = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(pdfData == nil)
                }
            }
            .onAppear {
                generatePDF()
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfData = pdfData {
                    ShareSheet(items: [pdfData])
                }
            }
        }
    }

    private func generatePDF() {
        isGeneratingPDF = true

        DispatchQueue.global(qos: .userInitiated).async {
            let generator = PDFGenerator()
            let data = generator.generatePDF(
                result: calculationState.result,
                calculationState: calculationState
            )

            DispatchQueue.main.async {
                self.pdfData = data
                self.isGeneratingPDF = false
            }
        }
    }
}

// MARK: - PDFプレビューコンポーネント
struct PDFPreview: View {
    let data: Data

    var body: some View {
        if let url = saveToTemporaryFile(data: data) {
            PDFKitView(url: url)
        } else {
            Text("PDFの表示に失敗しました")
                .foregroundColor(.red)
        }
    }

    private func saveToTemporaryFile(data: Data) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFile = tempDirectory.appendingPathComponent("refund_calculation.pdf")

        do {
            try data.write(to: tempFile)
            return tempFile
        } catch {
            print("Failed to save PDF to temporary file: \(error)")
            return nil
        }
    }
}

// MARK: - PDFKitView (UIViewRepresentable)
struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

// MARK: - 共有シート
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiView: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - PDF生成クラス（修正版：重複計算を排除）
class PDFGenerator {
    private let pageWidth: CGFloat = 595.2  // A4 width in points
    private let pageHeight: CGFloat = 841.8 // A4 height in points
    private let margin: CGFloat = 50

    /// PDF生成（修正：計算済みデータを活用）
    func generatePDF(result: RefundResult?, calculationState: RefundCalculationState) -> Data? {
        guard let result = result else { return nil }

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        return renderer.pdfData { context in
            context.beginPage()
            drawPDFContent(result: result, calculationState: calculationState)
        }
    }

    private func drawPDFContent(result: RefundResult, calculationState: RefundCalculationState) {
        var yPosition: CGFloat = margin

        // 1. ヘッダー
        yPosition = drawHeader(yPosition: yPosition)
        yPosition += 30

        // 2. 定期券詳細セクション
        yPosition = drawPassDetailSection(calculationState: calculationState, yPosition: yPosition)
        yPosition += 20

        // 3. 使用状況セクション
        yPosition = drawUsageStatusSection(result: result, calculationState: calculationState, yPosition: yPosition)
        yPosition += 20

        // 4. 払戻金額セクション
        yPosition = drawRefundCalculationSection(result: result, calculationState: calculationState, yPosition: yPosition)

        // 5. フッター
        drawFooter()
    }

    private func drawHeader(yPosition: CGFloat) -> CGFloat {
        let title = "定期券払戻計算書"
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]

        let titleSize = title.size(withAttributes: titleAttributes)
        let titleX = (pageWidth - titleSize.width) / 2

        title.draw(at: CGPoint(x: titleX, y: yPosition), withAttributes: titleAttributes)

        return yPosition + titleSize.height
    }

    private func drawPassDetailSection(calculationState: RefundCalculationState, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("▼ 定期券詳細", yPosition: currentY)
        currentY += 10

        let font = UIFont.systemFont(ofSize: 12)
        let dateFormatter = CommonDateFormatters.standard

        // 終了日を計算（通常払戻の場合のみ）
        let passDetailItems: [(String, String)]
        if calculationState.calculationType == .regular {
            let endDate = calculateEndDate(startDate: calculationState.startDate, passType: calculationState.passType)
            passDetailItems = [
                ("種別", calculationState.passType.description),
                ("期間", "\(dateFormatter.string(from: calculationState.startDate)) ～ \(dateFormatter.string(from: endDate))"),
                ("購入価格", "¥\(Int(calculationState.purchasePrice)?.formattedWithComma ?? "0")")
            ]
        } else {
            passDetailItems = [
                ("種別", calculationState.passType.description),
                ("開始日", dateFormatter.string(from: calculationState.startDate)),
                ("購入価格", "¥\(Int(calculationState.purchasePrice)?.formattedWithComma ?? "0")")
            ]
        }

        for (label, value) in passDetailItems {
            currentY = drawInfoRow(label: "\(label):", value: value, yPosition: currentY, font: font)
            currentY += 18
        }

        return currentY
    }

    private func drawUsageStatusSection(result: RefundResult, calculationState: RefundCalculationState, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("▼ 使用状況", yPosition: currentY)
        currentY += 10

        let font = UIFont.systemFont(ofSize: 12)
        let dateFormatter = CommonDateFormatters.standard

        // 払戻申請日
        currentY = drawInfoRow(
            label: "払戻申請日:",
            value: dateFormatter.string(from: calculationState.refundDate),
            yPosition: currentY,
            font: font
        )
        currentY += 18

        // 使用期間情報（修正：計算済みデータを活用）
        let usagePeriodInfo = createUsagePeriodInfo(calculationState: calculationState)
        currentY = drawInfoRow(
            label: "実際使用期間:",
            value: usagePeriodInfo,
            yPosition: currentY,
            font: font
        )
        currentY += 18

        // 使用分運賃
        currentY = drawInfoRow(
            label: "使用分運賃:",
            value: "¥\(result.usedAmount.formattedWithComma)",
            yPosition: currentY,
            font: font
        )
        currentY += 18

        // 計算根拠
        let calculationBasis = result.calculationDetails
        currentY = drawInfoRow(
            label: "　└ 計算根拠:",
            value: calculationBasis,
            yPosition: currentY,
            font: font
        )
        currentY += 18

        return currentY
    }

    private func drawRefundCalculationSection(result: RefundResult, calculationState: RefundCalculationState, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        let sectionTitle = "▼ 払戻金額（\(calculationState.calculationType.description)）"
        currentY = drawSectionTitle(sectionTitle, yPosition: currentY)
        currentY += 15

        let font = UIFont.systemFont(ofSize: 12)
        let boldFont = UIFont.boldSystemFont(ofSize: 12)
        let purchasePrice = Int(calculationState.purchasePrice) ?? 0

        // 計算詳細
        currentY = drawCalculationRow(
            label: "購入価格",
            value: "¥\(purchasePrice.formattedWithComma)",
            yPosition: currentY,
            font: font
        )
        currentY += 18

        currentY = drawCalculationRow(
            label: "使用分運賃",
            value: "-¥\(result.usedAmount.formattedWithComma)",
            yPosition: currentY,
            font: font
        )
        currentY += 18

        currentY = drawCalculationRow(
            label: "手数料",
            value: "-¥\(result.processingFee.formattedWithComma)",
            yPosition: currentY,
            font: font
        )
        currentY += 18

        // 罫線
        currentY = drawSeparatorLine(yPosition: currentY)
        currentY += 10

        // 払戻金額
        if result.refundAmount > 0 {
            currentY = drawCalculationRow(
                label: "払戻金額",
                value: "¥\(result.refundAmount.formattedWithComma)",
                yPosition: currentY,
                font: boldFont
            )
        } else {
            currentY = drawCalculationRow(
                label: "払戻金額",
                value: "払戻不可",
                yPosition: currentY,
                font: boldFont,
                isError: true
            )
        }

        return currentY + 30
    }

    private func drawSectionTitle(_ title: String, yPosition: CGFloat) -> CGFloat {
        let titleFont = UIFont.boldSystemFont(ofSize: 16)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]

        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)

        let titleSize = title.size(withAttributes: titleAttributes)
        return yPosition + titleSize.height
    }

    private func drawInfoRow(label: String, value: String, yPosition: CGFloat, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]

        if !label.isEmpty {
            label.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
            value.draw(at: CGPoint(x: margin + 150, y: yPosition), withAttributes: attributes)
        } else {
            value.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
        }

        let lineHeight = value.size(withAttributes: attributes).height
        return yPosition + lineHeight
    }

    private func drawFooter() {
        let footerText = "作成日時: \(CommonDateFormatters.pdfFooter.string(from: Date()))"
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]

        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerY = pageHeight - margin - footerSize.height
        let footerX = (pageWidth - footerSize.width) / 2

        footerText.draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttributes)
    }

    // MARK: - ヘルパーメソッド（修正：共通定数とヘルパーを使用）

    private func calculateEndDate(startDate: Date, passType: PassType) -> Date {
        return CalculationHelpers.calculateEndDate(startDate: startDate, passType: passType)
    }

    private func createUsagePeriodInfo(calculationState: RefundCalculationState) -> String {
        // 修正：共通ヘルパーを使用
        let elapsedDays = CalculationHelpers.calculateElapsedDays(
            from: calculationState.startDate,
            to: calculationState.refundDate
        )

        if calculationState.calculationType == .sectionChange {
            // 区間変更払戻の場合：旬数表示
            let usedJun = CalculationHelpers.calculateJun(from: elapsedDays)
            return "\(elapsedDays)日間（\(usedJun)旬）"
        } else {
            // 通常払戻の場合：7日以内の場合のみ特別表示、それ以外は日数のみ
            if elapsedDays <= CalculationConstants.withinSevenDaysThreshold {
                return "\(elapsedDays)日間（7日以内）"
            } else {
                return "\(elapsedDays)日間"
            }
        }
    }

    private func drawCalculationRow(label: String, value: String, yPosition: CGFloat, font: UIFont, isError: Bool = false) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]

        let valueColor = isError ? UIColor.systemRed : UIColor.black
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: valueColor
        ]

        // ラベルを左揃えで表示（適切な幅で調整）
        label.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: labelAttributes)

        // 値を右揃えで表示
        let valueSize = value.size(withAttributes: valueAttributes)
        let valueX = pageWidth - margin - valueSize.width
        value.draw(at: CGPoint(x: valueX, y: yPosition), withAttributes: valueAttributes)

        return yPosition + valueSize.height
    }

    private func drawSeparatorLine(yPosition: CGFloat) -> CGFloat {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setLineWidth(1.0)
        context?.move(to: CGPoint(x: margin, y: yPosition))
        context?.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
        context?.strokePath()

        return yPosition + 5
    }
}
