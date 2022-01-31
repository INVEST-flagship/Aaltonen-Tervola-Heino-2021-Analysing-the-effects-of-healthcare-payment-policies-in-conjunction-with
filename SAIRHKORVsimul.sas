

%TuhoaGlobaalit;

%LET START = &OUT;
%LET MALLI = SAIRHKORV;

%LET alkoi1&MALLI = %SYSFUNC(TIME());

/* 1. Mallia ohjaavat makromuuttujat */

%MACRO Aloitus;

/* Jos ohjelma ajetaan KOKO-mallin kautta, käytetään siellä määriteltyjä ohjaavien makromuuttujien arvoja */

%IF &START = 1 %THEN %DO;
	%LET TYYPPI = &TYYPPI_KOKO;
	%LET TULOKSET = 0;
%END;

/* Jos ohjelma ajetaan erillisajossa, käytetään alla syötettyjä ohjaavien makromuuttujien arvoja */

%IF &START NE 1 %THEN %DO;

	/* Seuraavia vaiheita ei ajeta jos arvot annetaan tämän koodin ulkopuolelta (&EG = 1) */

	%IF &EG NE 1 %THEN %DO;

	%LET AVUOSI = 2017;		* Aineistovuosi (vvvv);

	%LET LVUOSI = 2017;		* Lainsäädäntövuosi (vvvv);
							* HUOM! Jos käytät vuotta 2017, valitse TYYPPI = SIMULX;
							* ja haluamasi lainsäädäntökuukausi;
	%LET HINTAIND=1;

	%LET TYYPPI = SIMULX;	* Parametrien hakutyyppi: SIMUL (vuosikeskiarvo) tai SIMULX (parametrit haetaan tietylle kuukaudelle);

	%LET LKUUK = 12;		* Lainsäädäntökuukausi, jos parametrit haetaan tietylle kuukaudelle;


	%LET TULOSNIMI_SH = SAIRHKORV2020;	* Simuloidun tulostiedoston nimi ;

	* Inflaatiokorjaus. Euro- tai markkamääräisten parametrien haun yhteydessä suoritettavassa
	  deflatoinnissa käytettävän kertoimen voi syöttää itse INF-makromuuttujaan
	  (HUOM! desimaalit erotettava pisteellä .). Esim. jos yksi lainsäädäntövuoden euro on
	  aineistovuoden rahassa 95 senttiä, syötä arvoksi 0.95.
	  Simuloinnin tulokset ilmoitetaan aina aineistovuoden rahassa.
	  Jos puolestaan haluaa käyttää automaattista inflaatiokorjausta, on vaihtoehtoja kaksi:
	  - Elinkustannusindeksiin (kuluttajahintaindeksi, ind51) perustuva inflaatiokorjaus: INF = KHI
	  - Ansiotasoindeksiin (ansio64) perustuva inflaatiokorjaus: INF = ATI ;

	%LET INF = KHI; * Syötä lukuarvo, KHI tai ATI;
	%LET PINDEKSI_VUOSI = pindeksi_vuosi; *Käytettävä indeksien parametritaulukko;

	* Ajettavat osavaiheet ; 

	%LET POIMINTA = 1;  	* Muuttujien poiminta (1 jos ajetaan, 0 jos ei);
	%LET TULOKSET = 1;		* Yhteenvetotaulukot (1 jos ajetaan, 0 jos ei);

	%LET LAKIMAK_TIED_SH = SAIRHKORVlakimakrot;	* Lakimakrotiedoston nimi ;
	%LET PSAIRHKORV = psairhkorv; * Parametritaulukon nimi ;
	%LET PYKSTAKSA = pykstaksa; * Parametritaulukon nimi ;

	* Tulostaulukoiden esivalinnat ; 

	%LET TULOSLAAJ = 1 ; 	 * Mikrotason tulosaineiston laajuus (1 = suppea, 2 = laaja (kaikki pohja-aineiston muuttujat)) ;
	%LET MUUTTUJAT = KORV_SIMUL KORV_DATA OMAV_SIMUL OMAV_DATA; * Taulukoitavat muuttujat (summataulukot) ;
	%LET LUOK_KOTI1 = ; * Taulukoinnin 1. kotitalousluokitus 
							    Vaihtoehtoina: 
							     desmod (tulodesiilit, ekvivalentit tulot (modoecd), hlöpainot)
							     ikavuv (viitehenkilön mukaiset ikäryhmät)
							     elivtu (kotitalouden elinvaihe)
							     koulasv (viitehenkilön koulutusaste)
							     paasoss (viitehenkilön sosioekonominen asema)
							     rake (kotitalouden rakenne)
								 maakunta (NUTS3-aluejaon mukainen maakuntajako);
	%LET LUOK_KOTI2 = ; 	  * Taulukoinnin 2. kotitalousluokitus ;
	%LET LUOK_KOTI3 = ; 	  * Taulukoinnin 3. kotitalousluokitus ;

	%LET EXCEL = 0; 		  * Viedäänkö tulostaulukko automaattisesti Exceliin (1 = Kyllä, 0 = Ei) ;

	* Laskettavat tunnusluvut (jos tyhjä, niin ei lasketa);

	%LET SUMWGT = SUMWGT; * N eli lukumäärät ;
	%LET SUM = SUM; 
	%LET MIN = ; 
	%LET MAX = ;
	%LET RANGE = ;
	%LET MEAN = ;
	%LET MEDIAN = ;
	%LET MODE = ;
	%LET VAR = ;
	%LET CV =  ;
	%LET STD =  ;

	%LET PAINO = ykor ; 	* Käytettävä painokerroin (jos tyhjä, niin lasketaan painottamattomana) ;
	%LET RAJAUS =  ; 		* Rajauslause tunnuslukujen laskentaan (jos tyhjä, niin ei rajauksia);

	/* Lasketaan mahdollinen indeksiin perustuva inflaatiokorjaus */
	%END;
	%InfKerroin(&AVUOSI, &LVUOSI, &INF);

%END;

/* Ajetaan lakimakrot ja tallennetaan ne */

%INCLUDE "&LEVY&KENO&HAKEM&KENO.MAKROT&KENO&LAKIMAK_TIED_SH..sas";

%MEND Aloitus;

%Aloitus;

%LET alkoi2&malli = %SYSFUNC(TIME());



%MACRO SairHKorv_Simuloi_Data;

%LOCAL SAIRHKORV_PARAM SAIRHKORV_MUUNNOS;

%HaeLokaalit(SAIRHKORV_PARAM, SAIRHKORV);
%HaeLaskettavatLokaalit(SAIRHKORV_MUUNNOS, SAIRHKORV);

%LOCAL &SAIRHKORV_PARAM;

/* Jos parametrit luetaan makromuuttujiksi ennen simulontia, ajetaan tämä makro, erillisajossa */
%KuukSimul(SAIRHKORV);


*Yhdistetään yksityisen terveydenhuollon taksatiedot;
PROC SORT DATA=POHJADAT.YKSTERV&AVUOSI; BY toimk laji2; run;


DATA TEMP.&TULOSNIMI_SH._YK; MERGE 
POHJADAT.YKSTERV&AVUOSI(IN=A)
PARAM.&pykstaksa 

%IF &TYYPPI=SIMULX %THEN %DO; (KEEP = toimk tvoimpv tloppv taksa laji2 WHERE = (tvoimpv <= MDY(&lkuuk, 1, &lvuosi) <= tloppv)); BY toimk laji2; %END;
%IF &TYYPPI=SIMUL %THEN %DO; (KEEP = toimk tvoimpv tloppv taksa laji2); BY toimk laji2; IF tvoimpv <= MDY(maksukk, 1, &lvuosi) <= tloppv; %END;

IF A; DROP tvoimpv tloppv; laji=FLOOR(laji2); format laji sairkorvlaji.;


DATA TEMP.&TULOSNIMI_SH._YK; MERGE TEMP.&TULOSNIMI_SH._YK
PARAM.PYKSTHINNAT(KEEP=TOIMK V&LVUOSI RENAME=V&LVUOSI=HINTAIND);
by toimk;

IF not HINTAIND THEN DO;
	IF SUBSTR(toimk,1,4)='0101' THEN HINTAIND=&LaakarinPInd;
	ELSE HINTAIND=&MuuToim;
END;

RUN;

*Varsinainen yksityisen terveydenhuollon korvausten simulointi;

PROC SORT DATA=TEMP.&TULOSNIMI_SH._YK; BY TTEKNO; RUN;

DATA TEMP.&TULOSNIMI_SH._YK; SET TEMP.&TULOSNIMI_SH._YK;

%IF &HINTAIND=1 %THEN %DO; KUST_SIMUL=ROUND(kust*HINTAIND*&inf,0.01); %END;
%ELSE %DO; KUST_SIMUL=KUST; %END;

%YksTervKorv(KORV_SIMUL,&lvuosi,&lkuuk,&INF,taksa,KUST_SIMUL,aikakoro,erikkoro,kotikoro,laji2,kerrat,ttekno);

OMAV_SIMUL= SUM(KUST_SIMUL,-KORV_SIMUL);
IF FLOOR(laji2)=2 THEN DO; YKSSUU_SIMUL=OMAV_SIMUL; YKSSUU_DATA=OMAV_DATA; END;
ELSE DO; YKSTERV_SIMUL=OMAV_SIMUL; YKSTERV_DATA=OMAV_DATA; END;

ARRAY NOLLA KORV_DATA KORV_SIMUL YKSSUU_SIMUL YKSSUU_DATA YKSTERV_SIMUL YKSTERV_DATA;
DO OVER NOLLA;
	IF NOLLA=0 THEN NOLLA=.;
END;
RUN;

PROC SORT DATA=TEMP.&TULOSNIMI_SH._YK; BY hnro maksukk laji2; RUN;



*Matkakorvausten simulointi;

PROC SORT DATA=POHJADAT.MATKA&AVUOSI; BY hnro maksupv matpv;
DATA TEMP.&TULOSNIMI_SH._MA; SET POHJADAT.MATKA&AVUOSI;


%MatkaKustSimul(KUST_SIMUL,&lvuosi,12,&inf,SUM(omav_data,korv_data),kulkun);


*Korvaukset ilman matkakattoa;

%IF &TYYPPI = SIMULX %THEN %DO;
	%MatkaKorv&TYYPPI(KORV_SIMUL_temp,&lvuosi,&lkuuk,&inf,omav,matlkm,KUST_SIMUL,kilom,kulkun,taksikoro,yopymisraha);
%END;
%IF &TYYPPI = SIMUL %THEN %DO;
	%MatkaKorv&TYYPPI(KORV_SIMUL_temp,&lvuosi,month(MIN(maksupv,"31DEC&AVUOSI"d)),&inf,omav,matlkm,KUST_SIMUL,kilom,kulkun,taksikoro,yopymisraha);
%END;

OMAV_SIMUL_TEMP=MAX(0, SUM(KUST_SIMUL,-KORV_SIMUL_TEMP));

*Matkakaton simulointi;
%MatkaKatto(KORV_SIMUL,&lvuosi,&inf,KORV_SIMUL_temp,OMAV_SIMUL_temp,taksikoro,yopymisraha);

OMAV_SIMUL=MAX(0, SUM(KUST_SIMUL,-KORV_SIMUL));


*Jos tilataan keskuksen ulkopuolelta, toimeentulotuessa otetaan huomioon vain normaali omavastuu;
%IF &START = 1 %THEN %DO;

	IF taksikoro AND &LVUOSI>2014 THEN MATKATOTUOMAV = MIN(SUM(OMAV_SIMUL,KORV_SIMUL), omav * &MatkaOmavPerus);
	ELSE MATKATOTUOMAV = OMAV_SIMUL;

%END;

DROP OMAV_SIMUL_temp KORV_SIMUL_temp;

ARRAY NOLLA KORV_DATA KORV_SIMUL OMAV_DATA OMAV_SIMUL;
DO OVER NOLLA;
	IF NOLLA=0 THEN NOLLA=.;
END;
RUN;


*LABEL
KORV_SIMUL = 'Korvaukset, MALLI'
KORV_DATA = 'Korvaukset, DATA'
OMAV_SIMUL = 'Omavastuut, MALLI'
OMAV_DATA = 'Omavastuut, DATA';



%IF &START = 1 %THEN %DO;

	PROC SUMMARY DATA= TEMP.&TULOSNIMI_SH._YK NWAY; CLASS HNRO; OUTPUT OUT=TEMP.&TULOSNIMI_SH._YK(DROP=_type_ _freq_) SUM(YKSSUU_SIMUL YKSTERV_SIMUL)= ; RUN;
	%IF &TOTUTASO=KK %THEN %DO; PROC SUMMARY DATA= TEMP.&TULOSNIMI_SH._MA NWAY; CLASS HNRO MAKSUKK; OUTPUT OUT=TEMP.&TULOSNIMI_SH._MA_KK(DROP=_type_ _freq_ RENAME=MAKSUKK=KK) SUM(MATKATOTUOMAV)= ; RUN; %END;
	PROC SUMMARY DATA= TEMP.&TULOSNIMI_SH._MA NWAY; CLASS HNRO; OUTPUT OUT=TEMP.&TULOSNIMI_SH._MA(DROP=_type_ _freq_) SUM(OMAV_SIMUL MATKATOTUOMAV)= MATKAOMAV_SIMUL MATKATOTUOMAV; RUN;

%END;
%ELSE %DO;

	PROC SUMMARY DATA=TEMP.&TULOSNIMI_SH._YK NWAY; CLASS HNRO LAJI; ID YKOR; OUTPUT OUT=OUTPUT.&TULOSNIMI_SH._YK_HLO SUM(KORV_SIMUL KORV_DATA OMAV_SIMUL OMAV_DATA)=;
	PROC MEANS DATA=OUTPUT.&TULOSNIMI_SH._YK_HLO SUM SUMWGT NONOBS NOLABELS; CLASS LAJI; WEIGHT YKOR; VAR KORV_SIMUL KORV_DATA OMAV_SIMUL OMAV_DATA; 
	OUTPUT OUT=&TULOSNIMI_SH._YK_HLO_S SUMWGT=HLO_SIMUL HLO_DATA SUM= ; RUN;

	PROC SUMMARY DATA=TEMP.&TULOSNIMI_SH._MA NWAY; CLASS HNRO LAJI; ID YKOR; OUTPUT OUT=OUTPUT.&TULOSNIMI_SH._MA_HLO SUM(KORV_SIMUL KORV_DATA OMAV_SIMUL OMAV_DATA)=;
	PROC MEANS DATA=OUTPUT.&TULOSNIMI_SH._MA_HLO SUM SUMWGT NONOBS NOLABELS; CLASS LAJI; WEIGHT YKOR; VAR KORV_SIMUL KORV_DATA OMAV_SIMUL OMAV_DATA; 
	OUTPUT OUT=OUTPUT.&TULOSNIMI_SH._MA_HLO_S SUMWGT=HLO_SIMUL HLO_DATA SUM= ; RUN;

%END;


%MEND;
%SairHKorv_Simuloi_Data;

%LET loppui2&malli = %SYSFUNC(TIME());

%LET loppui1&malli = %SYSFUNC(TIME());

%LET kului1&malli = %SYSEVALF(&&loppui1&malli - &&alkoi1&malli);

%LET kului2&malli = %SYSEVALF(&&loppui2&malli - &&alkoi2&malli);

%LET kului1&malli = %SYSFUNC(PUTN(&&kului1&malli, time10.2));

%LET kului2&malli = %SYSFUNC(PUTN(&&kului2&malli, time10.2));

%PUT &malli. Koko laskenta. Aikaa kului (hh:mm:ss.00) &&kului1&malli;

%PUT &malli. Varsinainen simulointi. Aikaa kului (hh:mm:ss.00) &&kului2&malli;

