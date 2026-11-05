# ドパガキマインスイーパー（SwiftUI）

デザイン案「脳汁ネオン・ステッカー」をもとにした iOS アプリです。

## 動かし方

1. `DopagakiMinesweeper.xcodeproj` を Xcode 16 以降で開く
2. Signing & Capabilities で自分の Team を選ぶ
3. iPhone シミュレータか実機で実行（iOS 17 以降）

## 見出しフォント（任意）

見出しは Google Fonts の **Dela Gothic One**（OFL ライセンス）を想定しています。

1. https://fonts.google.com/specimen/Dela+Gothic+One から `DelaGothicOne-Regular.ttf` をダウンロード
2. `DopagakiMinesweeper/Fonts/` フォルダを作って ttf を入れる

フォルダに入れるだけで自動で読み込まれます。入れない場合は、システムの丸ゴシック（極太）で表示されます。

## 構成

| ファイル | 内容 |
|---|---|
| `Theme/Theme.swift` | 色、フォント、太フチ文字（PopText）、ステッカー、押すと沈むボタン、ギザギザ、画面揺れ、紙吹雪 |
| `Feedback/Feedback.swift` | 振動と効果音。効果音は音声ファイルなしでその場で合成する |
| `Model/Board.swift` | 盤面ロジック（初手保証、連鎖オープン、数字タップで周囲を一括オープン）、難易度 |
| `Model/GameViewModel.swift` | コンボ、スコア、フィーバー、レーダー、復活、勝敗、ランク |
| `Model/PlayerProgress.swift` | レベル、XP、コイン、ベストスコア、連続日数、設定（端末に保存） |
| `Views/` | タイトル、プレイ、クリア、ゲームオーバー、設定 |

## 遊び方とドーパミン要素

- タップで開く。長押しか「旗モード」で旗を立てる。数字をタップすると周囲を一括で開く
- 初手は必ず空白マスになり、大きく連鎖して開く
- 2秒以内に開け続けるとコンボが続き、音程が上がっていく
- 一度に10マス以上開くと CHAIN ボーナス。15マス以上で画面が揺れる
- フィーバーゲージが満タンになると8秒間スコア2倍
- レーダー（地雷に自動で旗）2回、復活1回
- クリアでランク（S〜C）、XP、コインを獲得し、レベルとステージが上がる
- 設定で効果音、振動、画面の揺れをオフにできる。端末の「視差効果を減らす」がオンの場合は揺れと紙吹雪を出さない
# DopagakiMinesweeper
