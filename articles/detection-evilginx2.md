---
title: "フィッシングサイトをテイクダウンせずに無効化する方法"
emoji: "📌"
type: "tech"
topics: ["javascript", "security", "nginx"]
published: false
---

## はじめに

前回記事をもう少し掘り下げてみました。  https://zenn.dev/tatsui/articles/1dff8410b7bdd7

@[tweet](https://twitter.com/defenceability/status/1628336214100316161)
@[tweet](https://twitter.com/mootastic/status/1628625149288382464)
@[tweet](https://twitter.com/WEB18619508/status/1629037444556546048)
インターネットには、フィッシング攻撃など、悪意のある脅威があふれています。
Evilginx2 は、最も危険なフィッシング攻撃の 1 つです。高度な技術を使用して検出を回避し、無防備な被害者から資格情報を盗みます。
幸いなことに、JavaScript ドメイン名チェックやフィッシング ブロッカーを使用するなど、Evilginx2 を検出して防止する方法があります。
本記事では、これらのツールを使用して Evilginx2 から保護する方法について説明します。

## 一般的なフィッシングサイトの対策手法
フィッシングサイトの対策はプロバイダーやGoogleセーフブラウジングに報告する事でDNSの名前解決やブラウザの保護機能を使ったテイクダウンが一般的ですが、報告から対策までの時間にボトルネックがあるため効率が悪いです。

## Evilginx2とは
Evilginx2 は、高度な技術を使用してセキュリティ対策を回避し、無防備な被害者から資格情報を盗む洗練されたフィッシング ツールです。
正当な Web ページ内に悪意のあるコードを隠したり、複数の難読化レイヤーを使用して悪意のあるペイロードを偽装したりするなど、さまざまな手法を組み合わせて検出を困難にしています。
また、検出を困難にする可能性のある認証および承認手段をバイパスすることもできます。

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
