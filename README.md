# AWS学習用Terraformプロジェクト

## 概要

このリポジトリは、Udemy講座のAWSハンズオンをTerraform（Infrastructure as Code）に書き換えた個人学習用のプロジェクトです。

元々はAWSコンソール上でインフラ構築を行う講座内容を、学習目的でTerraformコードとして実装し直したものです。

## プロジェクト構成

```
aws-14days/
├── Day2/                    # EC2とVPCの基本設定
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── Day3_4/                  # ネットワーク設定の拡張
│   └── main.tf
├── Day5/                    # インフラの拡張
│   └── main.tf
├── Day6/                    # ロードバランサーの設定
│   └── main.tf
├── Day7/                    # S3静的ウェブサイト
│   ├── main.tf
│   ├── index.html
│   └── s3/imgs/            # 画像ファイル
└── Day8/                    # Route53とドメイン設定
    ├── main.tf
    ├── index.html
    └── s3/imgs/            # 画像ファイル
```

## 学習内容

- **Day2**: EC2インスタンスとVPCの基本構成
- **Day3-4**: ネットワーク設定の理解と拡張
- **Day5**: インフラスケーリングの準備
- **Day6**: Application Load Balancerの実装
- **Day7**: S3を使った静的ウェブサイトホスティング
- **Day8**: Route53によるドメイン管理とSSL設定

## 使用技術

- Terraform
- AWS（EC2, VPC, S3, Route53, ALB等）
- HTML/CSS（静的サイト用）

## 注意事項

- これは個人の学習用リポジトリです
- 元となったUdemy講座の内容をTerraformで再実装したものです
- 実際にAWSリソースを作成するため、料金が発生する可能性があります
- 学習後は必要に応じて `terraform destroy` でリソースを削除してください

## 実行方法

各Dayフォルダに移動して以下のコマンドを実行：

```bash
terraform init
terraform plan
terraform apply
```

リソースの削除：
```bash
terraform destroy
```

## 免責事項

このプロジェクトは学習目的で作成されており、商用利用や配布を目的としたものではありません。
使用する際は自己責任でお願いします。