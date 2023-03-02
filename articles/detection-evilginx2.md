---
title: "フィッシングサイトをテイクダウンせずに無効化する方法"
emoji: "📌"
type: "tech"
topics: ["javascript", "security", "nginx"]
published: false
---

## はじめに

前回の記事をさらに掘り下げてみました。
https://zenn.dev/tatsui/articles/1dff8410b7bdd7

前回の記事では、正規のサイトと似たようなドメイン名からフィッシングサイトを探す方法について紹介しましたが、実際には、正規のドメインとは全く関係のないドメインを使用してフィッシングサイトを構築するパターンもあるようです。

@[tweet](https://twitter.com/defenceability/status/1628336214100316161)

一般的なフィッシングサイトの対策手法は、以下の2つに分類されます。
* クローラーやSaaSの活用
  * urlscan.io を使ったHTMLやJavascriptを解析
  * [SSL証明書の監視](http://phishing-hunter.com)
  * [類似ドメイン名のスキャン](http://demo.phishing-hunter.com)
* ブラウザの機能やアドオンによる検出
  * アンチウイルスベンダが公開しているアドオン
  * Googleセーフブラウジング
  * その他OSSで公開されているアドオン等

これらの手法を組み合わせることでフィッシングサイトを検出できる事がありますが、被害者を減らすために以下のような手順でフィッシングサイトのテイクダウンを実施する必要があります。

* フィッシングサイトが利用するISPやドメインレジストラーなどの情報を特定する。
* ISPやドメインレジストラーなどに対してテイクダウン依頼を行うための連絡先を確認する。
* テイクダウン依頼を行うための書面やメールなどを作成する。この際、フィッシングサイトのURLやIPアドレス、著作権侵害や不正行為の内容を具体的に記載し、証拠となるスクリーンショットやログファイルなども添付する必要がある。
* ISPやドメインレジストラーなどにテイクダウン依頼を送信する。依頼方法は、電話やメール、Webフォームなど様々な方法がある。
* ISPやドメインレジストラーなどからの回答を待つ。回答には時間がかかることがある。
* 回答があった場合、テイクダウンが成功したかどうかを確認する。成功した場合は、フィッシングサイトが利用していたドメイン名やIPアドレスなども削除されていることを確認する。

最近では、多要素認証を突破するリバースプロキシ型のEvilginx2などのフィッシングキットによって攻撃手法が巧妙化しており、ISPやドメインレジストラーの対応よりも早くこれらのフィッシングキットからサイトを保護する方法が必要となっています。
本記事では、これらのフィッシングキットからテイクダウン依頼をせずにサイトを保護する方法について説明します。

## Evilginx2とは
Evilginx2は、ログイン認証情報とセッションクッキーをフィッシングするための中間者攻撃フレームワークで、二要素認証を回避することができるツールです。 Evilginx2は、ブラウザとフィッシングされたウェブサイトの間にプロキシとして機能し、両者の間でやり取りされるデータをすべてキャプチャします。フィッシングされたユーザーは、本物のウェブサイトとやり取りすることになりますが、Evilginx2はその裏で認証情報やクッキーを盗みます。 Evilginx2は2017年にリリースされたEvilginxの後継ツールで、カスタムバージョンのNginx HTTPサーバーを使用しています。

## Evilginx2 を検出する方法

Evilginx2 を検出する 1 つの方法は、JavaScript を使って正規のドメインであるかどうか比較する方法です。
この方法は被害者がEvilginx2のリバースプロキシを経由して正規のサイトのコンテンツを表示した際にドメイン名が正規のサイトと異なるという特徴をJavascript側から検出します。
ドメイン名が想定されて正規表現にマッチしない場合は Web サイトが悪意のある可能性があり、ユーザーに警告を表示したりBodyタグ内のコンテンツを空の文字列に書き換えます。

以下がサンプルコードです。
```javascript
module.exports = function checkHostname(pattern, message="Phishing Scam Detected", replace_html=false) {
  let detect = true
  if (pattern.test(window.location.hostname)){
    detect = false;
  }
  if (window.location.hostname == 'localhost'){
    detect = false;
  }
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

上記のコードをパッケージとして公開したので以下のようにインストールするだけで簡単にセットアップすることができます。
```bash
npm install phishing-blocker
```

Webページの描画後に以下のようなコードを呼び出すことでドメインの検査を行うことが可能になります。
```javascript
const checkHostname = require('phishing-blocker');
var pattern = /^((www|dev)\.)?phishing-hunter\.com$/i;
checkHostname(pattern, "Phishing Scam Detected", true)
```

## まとめ
今回はフィッシング詐欺対策の手法としてJavascriptを使ってページを無効化する方法について解説しました。
Evilginx2はJavascriptを挿入することも可能なため、ドメイン名をチェックするだけでは不十分な可能性がありますが、攻撃の難易度をあげることが出来るため一定の効果は期待できそうです。

この記事を読んで、少しでもお役に立てたなら幸いです。何か質問やご意見がありましたら、お気軽にご連絡ください。


## 参考
https://www.freebuf.com/sectool/190646.html
https://www.blackhatethicalhacking.com/tools/evilginx2/
https://macrosec.tech/index.php/2021/01/25/phishing-attacks-with-evilginx2/
@[tweet](https://twitter.com/WEB18619508/status/1629037444556546048)
