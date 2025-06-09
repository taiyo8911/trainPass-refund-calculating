# trainPass-refund-calculating

# 通勤定期券払戻計算システム仕様書

## 1. システム概要
通勤定期券の払戻金額を自動計算するiOSアプリケーションシステム。通常払戻と区間変更払戻の2つの計算方式に対応し、定期券の種類（1ヶ月、3ヶ月、6ヶ月）に応じた正確な計算を実行する。

## 2. 機能仕様

### 2.1 対応する定期券種別
- **1ヶ月定期券**: 使用開始から7日以内の特別ルール適用
- **3ヶ月定期券**: 使用開始から7日以内の特別ルール適用、月単位での使用分運賃計算
- **6ヶ月定期券**: 使用開始から7日以内の特別ルール適用、月単位での使用分運賃計算、3ヶ月以上使用している場合は3ヶ月定期運賃を基準とした計算

### 2.2 払戻計算方式
1. **通常払戻** (`RegularRefundCalculator`)
   - 定期券の有効期間内での一般的な払戻
   - 残存月数が1ヶ月以上必要（1ヶ月定期除く）
   
2. **区間変更払戻** (`SectionChangeRefundCalculator`)
   - 定期券の区間変更に伴う払戻
   - 旬数（10日単位）での計算
   - 購入価格ベースの日割運賃による精密計算

## 3. データ構造

### 3.1 共通データ型（`CommonTypes.swift`）

#### PassType (定期券種別)
```swift
enum PassType: Int, CaseIterable {
    case oneMonth = 1      // 1ヶ月定期
    case threeMonths = 3   // 3ヶ月定期  
    case sixMonths = 6     // 6ヶ月定期
}
```

#### RefundResult (払戻結果)
```swift
struct RefundResult {
    let refundAmount: Int        // 最終払戻額
    let usedAmount: Int          // 使用分運賃
    let processingFee: Int       // 手数料（固定220円）
    let calculationDetails: String // 計算詳細説明
}
```

#### RefundCalculationType (払戻計算方式)
```swift
enum RefundCalculationType: String, CaseIterable {
    case regular = "regular"           // 通常払戻
    case sectionChange = "sectionChange" // 区間変更払戻
}
```

### 3.2 通常払戻用データ構造（`RegularRefundCalculator.swift`）

#### RefundData
- **基本入力項目**
  - `startDate`: 開始日
  - `passType`: 定期券種別
  - `purchasePrice`: 発売額
  - `refundDate`: 払戻日
  - `oneWayFare`: 片道普通運賃
  - `oneMonthFare`: 1ヶ月定期運賃
  - `threeMonthFare`: 3ヶ月定期運賃（6ヶ月定期の3ヶ月以上使用時の計算に必要）

- **自動計算項目**
  - `endDate`: 終了日（定期券有効期限）
  - `elapsedDays`: 使用日数（開始日含む）
  - `remainingDays`: 残存日数
  - `remainingMonths`: 残存月数
  - `usedMonths`: 使用月数
  - `roundTripFare`: 往復普通運賃（片道運賃×2）
  - `processingFee`: 払戻手数料（固定220円）

### 3.3 区間変更払戻用データ構造（`SectionChangeRefundCalculator.swift`）

#### SectionChangeRefundData
- **基本入力項目**
  - `startDate`: 開始日
  - `passType`: 定期券種別
  - `purchasePrice`: 発売額
  - `refundDate`: 払戻日

- **自動計算項目**
  - `elapsedDays`: 経過日数（開始日含む）
  - `usedJun`: 使用旬数（10日単位、端数は1旬扱い）
  - `dailyFare`: 日割運賃（1円未満切り上げ）
  - `processingFee`: 払戻手数料（固定220円）

## 4. 計算ロジック仕様

### 4.1 通常払戻計算 (`RegularRefundCalculator`)

#### 4.1.1 1ヶ月定期の払戻計算
- **使用開始から7日以内の場合**
  ```
  払戻額 = max(0, 購入価格 - (往復運賃 × 使用日数) - 手数料)
  ```
- **使用開始から8日以降の場合**
  ```
  払戻額 = 0円（払戻不可）
  ```

#### 4.1.2 3ヶ月定期の払戻計算
- **使用開始から7日以内の場合**
  ```
  払戻額 = max(0, 購入価格 - (往復運賃 × 使用日数) - 手数料)
  ```
- **使用開始から8日以降の場合**
  - 残存期間が1ヶ月以上必要
- **計算方式（月の区切りベース）**
  - **1-2ヶ月使用**: `使用分運賃 = 1ヶ月定期運賃 × 使用月数`
  ```
  払戻額 = 購入価格 - 使用分運賃 - 手数料
  ```

#### 4.1.3 6ヶ月定期の払戻計算
- **使用開始から7日以内の場合**
  ```
  払戻額 = max(0, 購入価格 - (往復運賃 × 使用日数) - 手数料)
  ```
- **使用開始から8日以降の場合**
  - 残存期間が1ヶ月以上必要
  - **3ヶ月定期運賃の入力が必須**
- **計算方式（月の区切りベース）**
  - **1-2ヶ月使用**: `使用分運賃 = 1ヶ月定期運賃 × 使用月数`
  - **3ヶ月以上使用**: `使用分運賃 = 3ヶ月定期運賃 + (1ヶ月定期運賃 × 追加月数)`
  ```
  払戻額 = 購入価格 - 使用分運賃 - 手数料
  ```

### 4.2 区間変更払戻計算 (`SectionChangeRefundCalculator`)

#### 4.2.1 旬数計算ロジック
```swift
使用旬数 = (経過日数 ÷ 10) + (端数 > 0 ? 1 : 0)
```

#### 4.2.2 日割運賃計算（購入価格ベース）
- **1ヶ月定期**: `日割運賃 = ceil(購入価格 ÷ 30)`
- **3ヶ月定期**: `日割運賃 = ceil(購入価格 ÷ 90)`
- **6ヶ月定期**: `日割運賃 = ceil(購入価格 ÷ 180)`

※1円未満切り上げ

#### 4.2.3 最終計算
```swift
使用分運賃 = 使用旬数 × 日割運賃 × 10
払戻額 = max(0, 購入価格 - 使用分運賃 - 手数料)
```

## 5. 入力要件

### 5.1 通常払戻の入力要件
- **全定期種別**: 購入価格、片道普通運賃、1ヶ月定期運賃
- **6ヶ月定期のみ**: 3ヶ月定期運賃（追加）

### 5.2 区間変更払戻の入力要件
- **全定期種別**: 購入価格のみ

### 5.3 共通入力検証
- `払戻日 ≥ 開始日`
- 通常払戻の場合: `払戻日 ≤ 定期券有効期限`
- 区間変更払戻の場合: `払戻日 ≤ 開始日 + 6ヶ月`（現実的な範囲内）

## 6. 使用月数計算ルール

### 6.1 月の区切りベース計算
- **7日以内**: 日数計算を使用（0ヶ月扱い）
- **8日目以降**: 月の区切りで計算

### 6.2 計算例（6月5日開始の場合）
- 6月5日〜6月11日（7日間） → 日数計算
- 6月12日〜7月4日 → 1ヶ月使用
- 7月5日〜8月4日 → 2ヶ月使用
- 8月5日〜9月4日 → 3ヶ月使用

## 7. 出力仕様

### 7.1 計算結果出力（RefundResult）
- **refundAmount**: 最終払戻額
- **usedAmount**: 使用分運賃
- **processingFee**: 払戻手数料（220円固定）
- **calculationDetails**: 計算詳細説明文

### 7.2 PDF出力機能
- A4サイズのPDF帳票出力
- 定期券詳細、使用状況、払戻金額の詳細表示
- 共有・保存機能

## 8. プロジェクト構造

### 8.1 Models
- `CommonTypes.swift`: 共通データ型定義
- `RegularRefundCalculator.swift`: 通常払戻計算ロジック
- `SectionChangeRefundCalculator.swift`: 区間変更払戻計算ロジック
- `RefundCalculationState.swift`: UI状態管理
- `CalculationConstants.swift`: 定数一元管理
- `ErrorHandling.swift`: 統一エラーハンドリング

### 8.2 Views
- `ContentView.swift`: メイン画面
- `InputFormView.swift`: データ入力画面
- `ResultModalView.swift`: 計算結果表示画面
- `PDFPreviewView.swift`: PDF出力・プレビュー画面

### 8.3 Test Files
- `RefundCalculatorTest.swift`: 包括的テストケース実装

### 8.4 App Configuration
- `train_pass_refund_calculating_systemApp.swift`: アプリエントリーポイント
- `Assets.xcassets/`: アプリアイコンとカラーリソース

## 9. テスト仕様

### 9.1 実装済みテストケース（`RefundCalculatorTest.swift`）

#### 通常払戻テスト
1. 1ヶ月定期（5日使用、7日以内）
2. 1ヶ月定期（15日使用、8日以降）
3. 3ヶ月定期（1ヶ月使用）
4. 3ヶ月定期（2ヶ月使用）
5. 6ヶ月定期（2ヶ月使用）
6. 6ヶ月定期（4ヶ月使用）
7. 境界値テスト（7日使用）

#### 区間変更払戻テスト
1. 1ヶ月定期（15日使用、2旬）
2. 3ヶ月定期（37日使用、4旬）
3. 6ヶ月定期（55日使用、6旬）
4. 旬数境界テスト（10日、11日）

#### 境界値テスト
1. 7日/8日境界テスト
2. 月境界テスト（使用月数計算）
3. 定数テスト

## 10. 技術仕様

### 10.1 開発環境
- **開発言語**: Swift
- **フレームワーク**: SwiftUI
- **対象プラットフォーム**: iOS
- **アーキテクチャ**: MVVM
- **日付処理**: Foundation.Calendar使用

### 10.2 エラーハンドリング
- **統一エラー型**: `RefundCalculationError`
- **安全な型変換**: `ErrorHandler.safeIntConversion`
- **バリデーション**: `ValidationResult`型
- **ログ記録**: `EnhancedLogger`
- **ユーザーメッセージ**: `UserMessageConverter`

### 10.3 共通ライブラリ
- **定数管理**: `CalculationConstants`
- **日付フォーマッター**: `CommonDateFormatters`
- **計算ヘルパー**: `CalculationHelpers`

## 11. 制約事項・特記事項

### 11.1 固定値
- 払戻手数料: 220円（固定）
- 日割計算基準日数: 1ヶ月=30日、3ヶ月=90日、6ヶ月=180日
- 7日以内ルール境界: 7日

### 11.2 計算精度
- 日割運賃は1円未満切り上げ
- 最終払戻額は0円未満にならない（max(0, 計算結果)）
- 使用月数は月の区切りベースで計算

### 11.3 安全性
- fatalErrorを使用しない安全な設計
- 全ての型変換でエラーハンドリング実装
- 包括的な入力検証

## 12. システムの特徴

### 12.1 改善された機能
- ✅ 購入価格ベースの区間変更払戻計算
- ✅ 正確な使用月数計算（月の区切りベース）
- ✅ 安全なエラーハンドリング（アプリクラッシュ防止）
- ✅ 定数の一元管理（保守性向上）
- ✅ 重複コードの排除（DRY原則）
- ✅ 包括的なテストカバレッジ

### 12.2 ユーザビリティ
- 直感的なUI設計
- リアルタイムバリデーション
- 詳細なエラーメッセージ
- PDF出力による記録保存

### 12.3 保守性・拡張性
- モジュラー設計
- 統一されたコーディング規約
- 詳細なドキュメント
- テストファーストアプローチ

## 13. 今後の拡張可能性

### 13.1 機能拡張
- 計算履歴保存機能
- 複数定期券の一括計算
- 外部APIとの連携
- 多言語対応

### 13.2 技術的拡張
- Core Data統合
- CloudKit同期
- Widget対応
- watchOS対応
