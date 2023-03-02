---
title: "フィッシングサイトをテイクダウンせずに無力化する方法"
emoji: "📌"
type: "tech"
topics: ["javascript", "security", "nginx", "phishing", "mfa"]
published: false
---

## はじめに

前回の記事をさらに掘り下げてみました。
https://zenn.dev/tatsui/articles/1dff8410b7bdd7

前回の記事では、正規のサイトと似たようなドメイン名からフィッシングサイトを探す方法について紹介しましたが、正規のドメインとは全く関係のないドメインを使用してフィッシングサイトを構築するパターンもあるようです。

@[tweet](https://twitter.com/defenceability/status/1628336214100316161)

一般的なフィッシングサイトの検出手法は、以下の2つに分類されます。
1. クローラーの実装やSaaSの活用
	- urlscan.io等を使ったHTMLやJavascript、スクリーンショットの解析
	- [SSL証明書の監視](http://phishing-hunter.com)
	- [類似ドメイン名のスキャン](http://demo.phishing-hunter.com)
2. ブラウザの機能やアドオンによる検出
	- Googleセーフブラウジング
	- アンチウイルスベンダが公開しているアドオン
	- その他OSSで公開されているアドオン等

これらの手法を組み合わせることでフィッシングサイトを検出できる事がありますが、被害者を増やさないためには以下のような手順でフィッシングサイトのテイクダウンを実施する必要があります。

1. フィッシングサイトが利用するISPやドメインレジストラーなどの情報を特定する。
1. ISPやドメインレジストラーなどに対してテイクダウン依頼を行うための連絡先を確認する。
1. テイクダウン依頼を行うための書面やメールなどを作成する。この際、フィッシングサイトのURLやIPアドレス、著作権侵害や不正行為の内容を具体的に記載し、証拠となるスクリーンショットやログファイルなども添付する必要がある。
1. ISPやドメインレジストラーなどにテイクダウン依頼を送信する。依頼方法は、電話やメール、Webフォームなど様々な方法がある。
1. ISPやドメインレジストラーなどからの回答を待つ。回答には時間がかかることがある。
1. 回答があった場合、テイクダウンが成功したかどうかを確認する。成功した場合は、フィッシングサイトが利用していたドメイン名やIPアドレスなども削除されていることを確認する。

:::message 
フィッシングサイトは接続元IPアドレスを確認して振る舞いを変えることがあるため、テイクダウンが完了するまで時間がかかることがあります。
:::

最近では、多要素認証を突破するEvilginx2などのフィッシングキットによって攻撃手法が巧妙化しており、ISPやドメインレジストラーの対応よりも早くこれらのフィッシングキットからサイトを保護する方法が必要となっています。
本記事では、これらのフィッシングキットからテイクダウン依頼をせずにサイトを保護する方法について説明します。

## Evilginx2とは
Evilginx2は、ログイン認証情報とセッションクッキーをフィッシングするための中間者攻撃フレームワークで、二要素認証を回避することができるツールです。 Evilginx2は、ブラウザとフィッシングされたウェブサイトの間にプロキシとして機能し、両者の間でやり取りされるデータをすべてキャプチャします。フィッシングされたユーザーは、本物のウェブサイトとやり取りすることになりますが、Evilginx2はその裏で認証情報やクッキーを盗みます。 Evilginx2は2017年にリリースされたEvilginxの後継ツールで、カスタムバージョンのNginx HTTPサーバーを使用しています。

以下のように実際にEvilginx2をローカルに構築してみて本物のサイトと比較してみました。

### 本物のサイト
![](/images/detection-evilginx2/1.png)
### Evilginx2を経由した偽サイト
:::message alert
Evilginx2の対策でサイトを表示すると正規ドメインと異なる場合に警告されるようになっていました。
:::
![](/images/detection-evilginx2/2.png)


## Evilginx2を検出し無力化する方法
Evilginx2を検出する方法の1つはJavaScriptで正しいドメインかどうかを比較することです。
この方法は、被害者がEvilginx2リバースプロキシを介して正規のサイトのコンテンツを表示するとき、JavaScript側でドメイン名が正しいサイトと異なることが検出されます。
もしドメイン名が正規表現に合致しない場合、悪意があるサイトの可能性があるため、ユーザーに警告を表示したりBodyタグ内のコンテンツを空の文字列に書き換えます。

以下がサンプルコードです。
```javascript
// pattern: ドメインパターンを受け取る正規表現オブジェクト
// message: フィッシングサイト検知時に表示するメッセージ
// replace_html: メッセージを表示する方法を選択するフラグ。trueの場合はHTMLを置換する。
module.exports = function checkHostname(pattern, message="Phishing Scam Detected", replace_html=false) {
  // 検知フラグ。初期値はtrue。
  let detect = true;
  // パターンにマッチするドメインでない場合は検知フラグをfalseにする。
  if (pattern.test(window.location.hostname)){
    detect = false;
  }
  // ローカルホストの場合は検知しない。
  if (window.location.hostname == 'localhost'){
    detect = false;
  }
  // 検知フラグがtrueの場合は、コンソールにメッセージを出力し、
  // HTMLを置換するかアラートダイアログを表示する。
  if (detect){
    console.error(message + " " + window.location.hostname)
    if (replace_html){
      document.getElementsByTagName('body')[0].innerHTML = message; 
    }else{
      alert(message);
    }
  }
}
```

上記のコードをパッケージとしても公開しているので以下のようにインストールするだけで簡単にセットアップすることができます。
```bash
npm install phishing-blocker
```

インストール後にWebページの描画後に以下のようなコードを呼び出すことでドメインの検査を行うことが可能になります。
```javascript
const checkHostname = require('phishing-blocker');
var pattern = /^((www|dev)\.)?phishing-hunter\.com$/i;
checkHostname(pattern, "Phishing Scam Detected", true)
```

## まとめ
今回は、フィッシング詐欺対策として、JavaScriptを使ってページを無力化する方法について説明しました。ただ、Evilginx2はJavaScriptを挿入できるため、ドメイン名のチェックだけでは不十分な場合があります。しかし、この方法を使うことで攻撃の難易度を上げることができるため、一定の効果が期待できます。
この記事を読んで、少しでもお役に立てたなら幸いです。何か質問やご意見がありましたら、お気軽にご連絡ください。


## 参考
https://www.freebuf.com/sectool/190646.html
https://www.blackhatethicalhacking.com/tools/evilginx2/
https://macrosec.tech/index.php/2021/01/25/phishing-attacks-with-evilginx2/
https://www.mbsd.jp/research/20230210/regex-url/
