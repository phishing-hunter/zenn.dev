---
title: "クラウドリソースのOSINT手法"
emoji: "👌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: 
  - aws
  - gcp
  - azure
  - cloud
  - security
published: false
---
## はじめに
近年、クラウドサービスの利用が急速に拡大しています。これらのサービスを利用することで、インフラやメンテナンスなどの負担が軽減され、ビジネスのスピードが向上します。
しかし、これらのサービスを悪用することで、データの漏洩や攻撃などのリスクも増加しています。
このような状況下で、クラウドで管理しているリソースに関する適切な公開設定が重要な役割を果たすようになっています。

## Certificate Transparencyとは
Certificate Transparency (CT)は、証明書を発行する認証局が実際に発行した証明書を公開する仕組みです。
この仕組みを活用することで、証明書の取得履歴を収集・分析することが可能となります。
CTの仕組みをAPIとして公開している[Certstream](https://certstream.calidog.io/)を使用することで、クラウドリソースの情報をリアルタイムに取得することが可能になります。

## 開発したツール
この証明書の取得履歴を収集するために、cert-hunterというツールを開発しました。
このツールは[CertstreamのAPI](https://github.com/CaliDog/certstream-python)を活用し、証明書の取得履歴を毎日保存しdockerコンテナとして配布しています。
証明書の取得履歴からクラウドストレージやCDNにホスティングされているドメイン名、アプリケーション名が取得でき、アプリやデータの内容が推測されます。

## 使い方
以下のように本日取得されたクラウドのリソースを探すことができます。
* AWS S3
```bash
docker run --rm -it -v $PWD:/work -w /work \
    phishinghunter/cert-hunter:latest \
    bash -c 'cat /csv/target.csv|grep s3.amazonaws.com'
```

* AWS Cloudfront
```bash
docker run --rm -it -v $PWD:/work -w /work \
    phishinghunter/cert-hunter:latest \
    bash -c 'cat /csv/target.csv|grep cloudfront.net'
```

* GCP Cloud Run
```bash
docker run --rm -it -v $PWD:/work -w /work \
    phishinghunter/cert-hunter:latest \
    bash -c 'cat /csv/target.csv|grep run.app'
```

* Azure Web Apps
```bash
docker run --rm -it -v $PWD:/work -w /work \
    phishinghunter/cert-hunter:latest \
    bash -c 'cat /csv/target.csv|grep azurewebsites.net'
```

* Cloudflare
```bash
docker run --rm -it -v $PWD:/work -w /work \
    phishinghunter/cert-hunter:latest \
    bash -c 'cat /csv/target.csv|grep cloudflare.net'
```

`latest`のタグがついたdockerイメージが最新のログを示しており、過去に取得されたログを検索したい場合はタグ名を以下のように変更してください。
```bash
docker run --rm -it -v $PWD:/work -w /work \
    phishinghunter/cert-hunter:20230201 \
    bash -c 'cat /csv/target.csv|grep s3.amazonaws.com'
```

## 注意点
ワイルドカード証明書を使用するクラウドリソースについては注意が必要です。
例えば[netlify](https://netlify.app/)の場合ワイルドカード証明書が使われているため、以下のように証明書を確認すると異なるFQDNで共通の証明書が使われていることがわかります。
```bash
$ openssl s_client -showcerts -connect phishing-hunter.netlify.app:443 2>/dev/null | openssl x509 -inform pem -noout -text| grep -1 'Serial Number'
        Version: 3 (0x2)
        Serial Number:
            02:5a:61:0f:58:eb:84:f1:ad:53:ae:03:dc:a9:84:7a
```

```bash
$ openssl s_client -showcerts -connect www.netlify.app:443 2>/dev/null | openssl x509 -inform pem -noout -text| grep -1 'Serial Number' 
        Version: 3 (0x2)
        Serial Number:
            02:5a:61:0f:58:eb:84:f1:ad:53:ae:03:dc:a9:84:7a
```
ワイルドカード証明書は複数のドメイン名に対して同時に使用することができる証明書であり、Certificate Transparencyでは検出することができません。

## 最後に
今回紹介したcert-hunterは過去に取得されたドメインの調査に特化しています。
証明書が発行されたタイミングで通知を受け取りたい場合は[こちら](https://phishing-hunter.com/)に登録してみてください。

インフラストラクチャが適切に設定されているかどうか確かめるきっかけとなれば幸いです。

## 参考
[eth0izzle/bucket-stream](https://github.com/eth0izzle/bucket-stream)
