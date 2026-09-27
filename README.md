# bio-repro-vcf-filter

## プロジェクト概要

**bcftoolsを使った、小さなVCFフィルタリングの再現性ポートフォリオ**です。入力・処理・Conda環境定義・出力例をまとめ、新しいConda環境で同じ結果が得られることを確認しました。

`synthetic.vcf` は学習用に自作した架空データです。架空の染色体 `synthetic_chr1` 上の16 SNPで構成し、実在患者・個人のデータやサンプル列は含みません。実データのダウンロードも不要です。

## 解決した問題

解析コマンドだけでは、ツールのバージョン、入力、フィルタ条件、期待結果が分からず、第三者による再実行・照合が難しくなります。本例ではこれらを明記し、独立したConda環境で出力のバイト単位の一致まで検証しました。

## フィルタ条件

次の両方を満たすvariantを抽出します。

- `QUAL >= 30`
- `INFO/DP >= 10`

`INFO/DP` はサイト単位の深度です。境界値は含め、QUALまたはINFO/DPが欠損した行は今回の条件では除外します。

## 使用技術とファイル

Bash、Conda、bcftools 1.24、HTSlib 1.24を使用します。

| ファイル | 役割 |
| --- | --- |
| synthetic.vcf | 自作の架空入力16件 |
| run.sh | フィルタリングとTSV出力 |
| environment.yml | チャネルと主要依存バージョン |
| filtered.vcf | 出力例6件 |
| summary.tsv | CHROM, POS, REF, ALT, QUAL, DPの出力例 |
| .gitignore | 一時ファイル・ログ・秘密情報等の除外設定 |
| LICENSE | 自作部分のMIT License |

小さな出力2ファイルは照合用の成果例としてGit管理します。ツール本体やConda環境は同梱しません。

## Conda環境作成手順

前提：Linux（WindowsではWSL）、Bash、利用可能なConda。以下はConda 26.5.3で確認済みです。リポジトリを取得・展開し、そのフォルダをカレントディレクトリにして実行してください。

同名の環境が既にある場合は上書きせず、別の名前を選び、以降の `-n` も合わせて変更してください。

```bash
conda create -n bio-repro-vcf-filter-test --file environment.yml \
  --override-channels -c conda-forge -c bioconda \
  --strict-channel-priority --no-default-packages -y
conda run -n bio-repro-vcf-filter-test bcftools --version
```

Conda 26.5.3の `conda create --file` でYAMLを読み込み、`-n` で環境名を指定します。YAMLのチャネルはconda-forge / bioconda / nodefaultsです。コマンド側でもdefaultsを除外し、グローバル設定やbaseを変更せず専用環境を作ります。

## 実行方法

```bash
conda run -n bio-repro-vcf-filter-test bash run.sh
```

スクリプトと同じフォルダに `filtered.vcf` と `summary.tsv` を出力します。既存の同名出力は上書きされます。VCFへの実行日時・コマンド追記は `--no-version` で抑制しています。

### 出力例を保持した再実行・比較

リポジトリのフォルダで、同じシェル内で実行してください。

```bash
checkdir=$(mktemp -d)
cp synthetic.vcf run.sh "$checkdir/"
conda run -n bio-repro-vcf-filter-test bash "$checkdir/run.sh"
cmp filtered.vcf "$checkdir/filtered.vcf"
cmp summary.tsv "$checkdir/summary.tsv"
sha256sum filtered.vcf "$checkdir/filtered.vcf" \
  summary.tsv "$checkdir/summary.tsv"
```

一致した場合、`cmp` は表示なし・終了コード0になります。新しい結果は一時フォルダ `$checkdir` にあります。

## 出力例

**入力16件 → 出力6件**。summary.tsvはヘッダー込み7行です。

```tsv
CHROM	POS	REF	ALT	QUAL	DP
synthetic_chr1	200	C	T	30	10
synthetic_chr1	500	A	C	60	20
synthetic_chr1	700	G	T	100	10
synthetic_chr1	1000	C	A	30	11
synthetic_chr1	1200	T	G	50	30
synthetic_chr1	1600	T	C	99	100
```

## 再現確認結果

2026-09-27、WSL Ubuntu / Linux x86_64、Conda 26.5.3で確認しました。

- 元環境とは別に、environment.ymlから `bio-repro-vcf-filter-test` を作成。
- bcftools 1.24（build `h118bc1c_2`）、HTSlib 1.24（build `ha79157c_0`）を使用。
- 未変更の入力・スクリプトから最後まで実行し、16件から6件を抽出。
- 元の結果と新規環境の結果が `cmp` とSHA-256で完全一致。
- 手書き期待TSV、閾値ちょうど・閾値未満・欠損値の扱いも確認。

| 出力 | 一致したSHA-256 |
| --- | --- |
| filtered.vcf | `f62ded5968b3aee1bfde02ace19de641ad4b559561a9545f907853e50fdcac49` |
| summary.tsv | `aede9083ef5a5ef9f5939dd3958cf470e3dbd483c7896e4fb252ff4f66276ae2` |

## 制約事項

- 同一PC上の別Conda環境で検証しています。別PC・別OSは未確認です。
- YAMLはbcftools / HTSlibのバージョンのみ固定し、間接依存やビルドを完全固定するロックファイルではありません。
- 小規模な架空SNPデータの練習例です。実研究・診断への閾値の妥当性、大規模VCFや複雑なvariantへの適用は検証していません。
- 依存関係全体の自動脆弱性監査は未実施です。

## 出典・ライセンス

自作のスクリプト・設定・文書・syntheticデータとその出力例は [MIT License](LICENSE) で提供します。著作権者はmakomako83です。このライセンスは依存ツールには適用しません。

- **bcftools**：[公式リポジトリ](https://github.com/samtools/bcftools)、[マニュアル](https://samtools.github.io/bcftools/bcftools.html)、[1.24のLICENSE](https://github.com/samtools/bcftools/blob/1.24/LICENSE)。MIT/ExpatまたはGPLの選択制で、GSLを組み込む場合はGPLが適用されます。今回のBiocondaビルドの実行時表示はGPLv3+です。
- **HTSlib**：[公式リポジトリ](https://github.com/samtools/htslib)、[1.24のLICENSE](https://github.com/samtools/htslib/blob/1.24/LICENSE)。原則MIT/Expat、cramディレクトリはModified 3-Clause BSDです。
- 配布元：[Bioconda bcftools](https://bioconda.github.io/recipes/bcftools/README.html)。依存ツールはCondaから別途取得し、それぞれのライセンスに従います。
