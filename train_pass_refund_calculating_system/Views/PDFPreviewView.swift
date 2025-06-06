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
                calculationType: calculationState.calculationType,
                inputData: createInputDataForPDF()
            )

            DispatchQueue.main.async {
                self.pdfData = data
                self.isGeneratingPDF = false
            }
        }
    }

    private func createInputDataForPDF() -> PDFInputData {
        return PDFInputData(
            calculationType: calculationState.calculationType,
            passType: calculationState.passType,
            startDate: calculationState.startDate,
            refundDate: calculationState.refundDate,
            purchasePrice: Int(calculationState.purchasePrice) ?? 0,
            oneWayFare: Int(calculationState.oneWayFare),
            oneMonthFare: Int(calculationState.oneMonthFare) ?? 0,
            threeMonthFare: Int(calculationState.threeMonthFare)
        )
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

// MARK: - PDF生成データ構造
struct PDFInputData {
    let calculationType: RefundCalculationType
    let passType: PassType
    let startDate: Date
    let refundDate: Date
    let purchasePrice: Int
    let oneWayFare: Int?
    let oneMonthFare: Int
    let threeMonthFare: Int?
}

// MARK: - PDF生成クラス
class PDFGenerator {
    private let pageWidth: CGFloat = 595.2  // A4 width in points
    private let pageHeight: CGFloat = 841.8 // A4 height in points
    private let margin: CGFloat = 50

    func generatePDF(result: RefundResult?, calculationType: RefundCalculationType, inputData: PDFInputData) -> Data? {
        guard let result = result else { return nil }

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        return renderer.pdfData { context in
            context.beginPage()
            drawPDFContent(result: result, calculationType: calculationType, inputData: inputData)
        }
    }

    private func drawPDFContent(result: RefundResult, calculationType: RefundCalculationType, inputData: PDFInputData) {
        var yPosition: CGFloat = margin

        // ヘッダー
        yPosition = drawHeader(yPosition: yPosition)
        yPosition += 30

        // 基本情報
        yPosition = drawBasicInfo(inputData: inputData, yPosition: yPosition)
        yPosition += 20

        // 計算結果
        yPosition = drawResult(result: result, yPosition: yPosition)
        yPosition += 20

        // 計算詳細
        yPosition = drawCalculationDetails(result: result, calculationType: calculationType, yPosition: yPosition)

        // フッター
        drawFooter()
    }

    private func drawHeader(yPosition: CGFloat) -> CGFloat {
        let title = "通勤定期券払戻計算書"
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

    private func drawBasicInfo(inputData: PDFInputData, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("基本情報", yPosition: currentY)
        currentY += 10

        let font = UIFont.systemFont(ofSize: 12)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        // 情報項目
        let basicInfoItems = [
            ("計算方式", inputData.calculationType.description),
            ("定期券種別", inputData.passType.description),
            ("開始日", dateFormatter.string(from: inputData.startDate)),
            ("払戻日", dateFormatter.string(from: inputData.refundDate)),
            ("購入価格", "¥\(inputData.purchasePrice.formattedWithComma)"),
            ("1ヶ月定期運賃", "¥\(inputData.oneMonthFare.formattedWithComma)")
        ]

        var items = basicInfoItems

        if let oneWayFare = inputData.oneWayFare {
            items.append(("片道普通運賃", "¥\(oneWayFare.formattedWithComma)"))
        }

        if let threeMonthFare = inputData.threeMonthFare {
            items.append(("3ヶ月定期運賃", "¥\(threeMonthFare.formattedWithComma)"))
        }

        for (label, value) in items {
            currentY = drawInfoRow(label: label, value: value, yPosition: currentY, font: font)
            currentY += 5
        }

        return currentY
    }

    private func drawResult(result: RefundResult, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("計算結果", yPosition: currentY)
        currentY += 10

        // 払戻額（大きく表示）
        let refundAmountText = "¥\(result.refundAmount.formattedWithComma)"
        let refundFont = UIFont.boldSystemFont(ofSize: 28)
        let refundColor = result.refundAmount > 0 ? UIColor.systemGreen : UIColor.systemRed
        let refundAttributes: [NSAttributedString.Key: Any] = [
            .font: refundFont,
            .foregroundColor: refundColor
        ]

        let refundSize = refundAmountText.size(withAttributes: refundAttributes)
        let refundX = (pageWidth - refundSize.width) / 2
        refundAmountText.draw(at: CGPoint(x: refundX, y: currentY), withAttributes: refundAttributes)
        currentY += refundSize.height + 15

        // 結果詳細
        if result.refundAmount > 0 {
            let font = UIFont.systemFont(ofSize: 12)
            let resultItems = [
                ("使用分運賃", "¥\(result.usedAmount.formattedWithComma)"),
                ("手数料", "¥\(result.processingFee.formattedWithComma)")
            ]

            for (label, value) in resultItems {
                currentY = drawInfoRow(label: label, value: value, yPosition: currentY, font: font)
                currentY += 5
            }
        }

        return currentY
    }

    private func drawCalculationDetails(result: RefundResult, calculationType: RefundCalculationType, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("計算詳細", yPosition: currentY)
        currentY += 10

        // 詳細内容
        let detailFont = UIFont.systemFont(ofSize: 11)
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: UIColor.darkGray
        ]

        let detailText = result.calculationDetails
        let detailRect = CGRect(
            x: margin,
            y: currentY,
            width: pageWidth - 2 * margin,
            height: 200 // 十分な高さを確保
        )

        detailText.draw(in: detailRect, withAttributes: detailAttributes)

        return currentY + 50 // 適当な高さを追加
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

        label.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
        value.draw(at: CGPoint(x: margin + 150, y: yPosition), withAttributes: attributes)

        let lineHeight = label.size(withAttributes: attributes).height
        return yPosition + lineHeight
    }

    private func drawFooter() {
        let footerText = "作成日時: \(DateFormatter.current.string(from: Date()))"
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
}

extension DateFormatter {
    static let current: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter
    }()
}
