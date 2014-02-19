Narou.rb ― 「小説家になろう」「小説を読もう！」ダウンローダ＆縦書用整形スクリプト
============================================================

概要 - Summary
--------------
このアプリは[小説家になろう](http://syosetu.com/)、[小説を読もう！](http://yomou.syosetu.com/)で公開されている小説の管理、
及び電子書籍データへの変換を支援します。縦書き用に特化されており、
横書き用に特化されたWEB小説を違和感なく縦書きで読むことが出来るようになります。
また、若干の校正機能もありますので、小説としての一般的な整形ルールに矯正します。（例：感嘆符のあとにはスペースが必ずくる）

[ノクターンノベルズ](http://noc.syosetu.com/)及び[ムーンライトノベルズ](http://mnlt.syosetu.com/)にも対応しています。

全てコンソールで操作するCUIアプリケーションです。

主な機能は小説家になろうの小説のダウンロード、更新管理、テキスト整形、AozoraEpub3・kindlegen連携によるEPUB/MOBI出力です。

詳細な説明やインストール方法は **[Narou.rb 説明書](https://github.com/whiteleaf7/narou/wiki)** を御覧ください。

![ScreenCapture](https://raw.github.com/wiki/whiteleaf7/narou/images/narou_cap.gif)

更新履歴 - ChangeLog
--------------------

2014/02/20 : **1.4.0**
* 重要な修正
	- 小説家になろうのレイアウト変更によって更新処理ができなくなっていたものを修正しました

2014/02/03 : **1.3.5.1**
* Bug Fix
	- 過去バージョンとの互換性維持のため、フォルダ名のみ末尾スペースを削除するように変更

2014/02/03 : **1.3.5**
* Bug Fix
	- 小説を削除したあと再度ダウンロードしようとした場合にエラーが出ていたのを修正
	- タイトル名の末端に半角スペースがある小説が正常にダウンロード出来ない問題を修正
* 追加機能もしくは仕様変更
	- 小説変換プリセットに n2525bs (魔剣ゾルディの女主人公とっかえひっかえ成長記録) 追加
	- ダウンロードが完了した時に同時に凍結させるオプションを追加
		+ `download` コマンドに `--freeze` (短縮名 -z) オプションが追加されました
			* コマンド例： `narou download --freeze n4029bs`
			* コマンド例： `narou d n4029bs -z`
	- Mac上での動作改善コードの取り込み（https://github.com/yossoy/narou）
		+ java の動作不良対応、Kindle 対応

2013/12/25 : **1.3.4**
* Bug Fix
	- `narou init` 時に "" で囲まれたパスを認識できない不具合を修正

2013/10/30 : **1.3.3**
* 追加機能もしくは仕様変更
	- 送信対応端末に SonyReader(PRS-T2) を追加
		+ `narou setting device=reader` で切り替えることが出来ます

2013/10/29 : **1.3.2**
* 追加機能もしくは仕様変更
	- `default_args.*` の設定が使われるのは、各コマンドの引数が省略された時だけに変更
	- 各端末のボリュームラベルを大文字小文字区別しないで認識するように変更（Windowsのみ）
	- ダイジェスト化の自動検知機能を搭載。更新するかしないか、凍結してしまうかを選択可能に

----

「小説家になろう」は株式会社ヒナプロジェクトの登録商標です
