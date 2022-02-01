# Tervola, Heino & Aaltonen (2021) Analysing the effects of healthcare payment policies in conjunction with tax-benefit policies: A microsimulation study with real-world  healthcare data
## A code repository for statistical analyses

Jussi Tervola, Pekka Heino & Katri Aaltonen

[![DOI](https://zenodo.org/badge/453912515.svg)](https://zenodo.org/badge/latestdoi/453912515)

## Introduction

Repository for the codes used for the analyses of Aaltonen, Tervola & Heino (2021) Analysing the effects of healthcare payment policies in conjunction with tax-benefit policies: A microsimulation study with real-world  healthcare data. Analyses in the article were conducted using SAS.

The study was conducted using national tax-benefit microsimulation model, SISU, and its nationally representative 15% sample of households in Finland in 2017 (n=826,001) linked with administrative real-world healthcaredata (Finnish Institute for Health and Welfare Care Register for Health Care, HILMO; and Social Insurance Institution of Finland, Kela, National Health Insurance reimbursement registers).

The full article can be found at: https://osf.io/preprints/socarxiv/m7h3u/

## About the codes

Codes are divided into three legislation modules: public healthcare user charges (ASMAKSU), reimbursements for prescribed medicines (LAAKE) and reimbursement for private health care and travel expenses (SAIRHKORV). Master module (KOKO) runs all afore-mentioned modules and other SISU legislation modules, which are available at https://www.stat.fi/tup/mikrosimulointi/lataus.html.

In addition, modules have different types of files (datamuok = raw data editing code, lakimakrot = legislation macros, simul = actual simulation code). Sub-modules can also be run from the "simul"-files independently without the master module.

PASMAKSU, PLAAKE and PSAIRHKORV tables contain numerical parameters of legislation in different years

## Output examples

<img width="979" alt="Screenshot 2022-01-31 at 9 51 35" src="https://user-images.githubusercontent.com/75479046/151757241-c1dcaa38-b78d-4ea5-9167-c471338e236c.png">

<img width="958" alt="Screenshot 2022-01-31 at 9 50 48" src="https://user-images.githubusercontent.com/75479046/151757265-2bb491d6-2990-4c22-9af5-ad3096a68a63.png">

## Cite as

Jussi Tervola, Pekka Heino & Katri Aaltonen (2021) INVEST-flagship/Tervola-Heino-Aaltonen-2021-Analysing-the-effects-of-healthcare-payment-policies-in-conjunction-with-tax-benefit-policies-A-microsimulation-study-with-real-world-healthcare-data. Zenodo. http://doi.org/10.5281/zenodo.5930173.

## License

Creative Commons Attribution 4.0 International
