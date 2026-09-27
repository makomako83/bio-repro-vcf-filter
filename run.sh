#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v bcftools >/dev/null || { echo "bcftools is required; use the dedicated Conda environment." >&2; exit 1; }
bcftools view --no-version -i 'QUAL >= 30 && INFO/DP >= 10' -Ov -o filtered.vcf synthetic.vcf
{
    printf 'CHROM\tPOS\tREF\tALT\tQUAL\tDP\n'
    bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t%INFO/DP\n' filtered.vcf
} > summary.tsv
