/*********************************************************
* Kuvaus: Reseptil��kkeiden  simulointimalli 2017        *
* Viimeksi p�ivitetty: 14.5.2020 						 *
*********************************************************/ 

/* 0. Yleisi� vakioiden m��rittelyj� (�l� muuta n�it�!) */

%TuhoaGlobaalit;

%LET START = &OUT;

%LET MALLI = LAAKE;

%LET alkoi1&MALLI = %SYSFUNC(TIME());


/* 1. Mallia ohjaavat makromuuttujat */

%MACRO Aloitus;

/* Jos ohjelma ajetaan KOKO-mallin kautta, k�ytet��n siell� m��riteltyj� ohjaavien makromuuttujien arvoja */
%LET TAKSAT = 1;
 
%IF &START = 1 %THEN %DO;
	%LET TYYPPI = &TYYPPI_KOKO;
	%LET TULOKSET = 0;
%END;

/* Jos ohjelma ajetaan erillisajossa, k�ytet��n alla sy�tettyj� ohjaavien makromuuttujien arvoja */

%IF &START NE 1 %THEN %DO;
%loki(0);
	/* Seuraavia vaiheita ei ajeta jos arvot annetaan t�m�n koodin ulkopuolelta (&EG = 1) */

	%IF &EG NE 1 %THEN %DO;
			
		%LET AVUOSI = 2017;								/* Aineistovuosi (vvvv) */

		%LET LVUOSI = 2010;								/* Lains��d�nt�vuosi (vvvv) */

		%LET TYYPPI = SIMULX;							/* Parametrien hakutyyppi: SIMUL (vuosikeskiarvo) tai SIMULX (parametrit haetaan tietylle kuukaudelle);*/
		

		%LET LKUUK = 12;       							/* Lains��d�nt�kuukausi, jos parametrit haetaan tietylle kuukaudelle;*/

		%LET AINEISTO = OTOS; /*REK;*/	/* K�ytett�v� aineisto (PALV = Palveluaineisto, REK = Rekisteriaineisto) */
                             /* Lasketaan taksat. 0=ei, 1=kyll� */
		%LET HINTAIND = 1;                               /* Lasketaan l��keindeksit. 0=ei, 1=kyll� */	
		/********************/
		%LET TULOSNIMI_LA = laake_simul&hintaind;	/* Simuloidun tulostiedoston nimi */	
	* Inflaatiokorjaus. Euro- tai markkam��r�isten parametrien haun yhteydess� suoritettavassa
	  deflatoinnissa k�ytett�v�n kertoimen voi sy�tt�� itse INF-makromuuttujaan
	  (HUOM! desimaalit erotettava pisteell� .). Esim. jos yksi lains��d�nt�vuoden euro on
	  aineistovuoden rahassa 95 sentti�, sy�t� arvoksi 0.95.
	  Simuloinnin tulokset ilmoitetaan aina aineistovuoden rahassa.
	  Jos puolestaan haluaa k�ytt�� automaattista inflaatiokorjausta, on vaihtoehtoja kaksi:
	  - Elinkustannusindeksiin (kuluttajahintaindeksi, ind51) perustuva inflaatiokorjaus: INF = KHI
	  - Ansiotasoindeksiin (ansio64) perustuva inflaatiokorjaus: INF = ATI ;

	%LET INF = KHI; * Sy�t� lukuarvo, KHI tai ATI;
	%LET PINDEKSI_VUOSI = pindeksi_vuosi; *K�ytett�v� indeksien parametritaulukko;		
		
	/* Ajettavat osavaiheet */ 
	%LET POIMINTA = 1;  							/* Muuttujien poiminta (1 jos ajetaan, 0 jos ei) */
	%LET TULOKSET = 1;								/* Yhteenvetotaulukot (1 jos ajetaan, 0 jos ei) */

	%LET LAKIMAK_TIED_LA = LAAKElakimakrot;			/* Lakimakrotiedoston nimi */
	%LET PLAAKE = plaake; 				/* K�ytett�v�n parametritiedoston nimi */

	/* Tulosten valinnat */ 
	%LET TULOSLAAJ = 1; 	 						/* Mikrotason tulosaineiston laajuus (1 = suppea, 2 = laaja (kaikki pohja-aineiston muuttujat)) */
	%LET YKSIKKO = 1;		 						/* Mikrotason tulosaineiston ja summataulukoiden yksikk� (1 = henkil�, 2 = kotitalous) */
	/* T�h�n pit�� viel� mietti� muuttujat */
	%LET MUUTTUJAT = LAAKE_SIMUL LAAKEIV_SIMUL KORV_SIMUL KAKORV_SIMUL LAAKE_DATA; 			/* Summataulukoissa taulukoitavat muuttujat */
	%LET LUOK_HLO1 = ; 		 						/* Taulukoinnin 1. henkil�luokitus (jos YKSIKKO = 1)
							   						   Vaihtoehtoina: 
							     					    desmod (tulodesiilit, ekvivalentit tulot (modoecd), hl�painot)
							     						ikavu (ik�ryhm�t)
							     						elivtu (kotitalouden elinvaihe)
							     						koulas (koulutusaste)
							     						soss (sosioekonominen asema)
							     						rake (kotitalouden rakenne)
								 						maakunta (NUTS3-aluejaon mukainen maakuntajako) */
	%LET LUOK_HLO2 = ;		 						/* Taulukoinnin 2. henkil�luokitus */
	%LET LUOK_HLO3 = ;		 						/* Taulukoinnin 3. henkil�luokitus */
	%LET LUOK_KOTI1 = ; 							/* Taulukoinnin 1. kotitalousluokitus (jos YKSIKKO = 2)  
							    					   Vaihtoehtoina: 
							     						desmod (tulodesiilit, ekvivalentit tulot (modoecd), hl�painot)
													    ikavuv (viitehenkil�n mukaiset ik�ryhm�t)
													    elivtu (kotitalouden elinvaihe)
													    koulasv (viitehenkil�n koulutusaste)
													    paasoss (viitehenkil�n sosioekonominen asema)
													    rake (kotitalouden rakenne)
														maakunta (NUTS3-aluejaon mukainen maakuntajako) */
	%LET LUOK_KOTI2 = ; 	  						/* Taulukoinnin 2. kotitalousluokitus */
	%LET LUOK_KOTI3 = ; 	  						/* Taulukoinnin 3. kotitalousluokitus */

	%LET EXCEL = 0; 		 						/* Vied��nk� tulostaulukko automaattisesti Exceliin (1 = Kyll�, 0 = Ei) */

	/* Laskettavat tunnusluvut (jos tyhj�, niin ei lasketa) */
	%LET SUMWGT = ; 							/* N eli lukum��r�t */
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

	%LET PAINO = ykor; 							/* K�ytett�v� painokerroin (jos tyhj�, niin lasketaan painottamattomana) */
	%LET RAJAUS =  ; 								/* Rajauslause tunnuslukujen laskentaan (jos tyhj�, niin ei rajauksia) */

	%END;


	

	/* Lasketaan mahdollinen indeksiin perustuva inflaatiokorjaus */

	%InfKerroin(&AVUOSI, &LVUOSI, &INF);

%END;

/* Ajetaan lakimakrot ja tallennetaan ne */

%INCLUDE "&LEVY&KENO&HAKEM&KENO.MAKROT&KENO&LAKIMAK_TIED_LA..sas";

%MEND Aloitus;

%Aloitus;

/* 2. Datan poiminta ja apumuuttujien luominen (optio) */
/* Ei viel� lopullinen */
%MACRO Laake_Muutt_Poiminta;
%IF &POIMINTA = 1 %THEN %DO;
	PROC SORT DATA=POHJADAT.LAAKEOSTOT_HINNAT&AVUOSI; BY HNRO;
	DATA STARTDAT.START_LAAKE; 
	MERGE POHJADAT.&AINEISTO&AVUOSI(keep=hnro ykor in=a)
	POHJADAT.LAAKEOSTOT_HINNAT&AVUOSI(in=b
		KEEP = hnro atc  ika jtjno anja kakorv korv kust laji romav rvmk otpvm plkm RVMK_KERTY ATC3
		LAJI_NUM OSTOS 	%IF &TAKSAT = 1 %THEN %DO; RSTATUS THINTA VOALPV VOLOPV SUBKOODI VHINTA VIHINTA VNRON KAUSI RGENK RTUN %END;
	); by hnro; if a and b;
	run;
%END;
%MEND Laake_Muutt_Poiminta;

%Laake_Muutt_Poiminta;

/* 3. Simulointivaihe */

%LET alkoi2&malli = %SYSFUNC(TIME());

/* 3.1 Varsinainen simulointivaihe */

%MACRO Laake_Simuloi_Data;
/* LAAKE-mallin parametrit */
%LOCAL LAAKE_PARAM LAAKE_MUUNNOS;

/* Haetaan mallin k�ytt�mien lakiparametrien nimet */
%HaeLokaalit(LAAKE_PARAM, LAAKE);
%HaeLaskettavatLokaalit(LAAKE_MUUNNOS, LAAKE);

/* Luodaan tyhj�t lokaalit muuttujat lakiparametien hakua varten */
%LOCAL &LAAKE_PARAM;

%PUT HINTAIND &HINTAIND TAKSAT &TAKSAT INF &INF;
/* Jos parametrit luetaan makromuuttujiksi ennen simulontia, ajetaan t�m� makro, erillisajossa */
 %KuukSimul(LAAKE);

	proc sort data=STARTDAT.START_LAAKE; by atc3;run;
	proc sort data=PARAM.PLAAKEIND; by atc3;run;
	DATA TEMP.&TULOSNIMI_LA;
	
		MERGE STARTDAT.START_LAAKE PARAM.PLAAKEIND(keep=V&LVUOSI Atc3);
		BY atc3;

		%IF &HINTAIND=1 %THEN %DO;
			KUST=V&LVUOSI*KUST*&inf;
			RVMK=V&LVUOSI*RVMK*&inf;
			THINTA=V&LVUOSI*THINTA*&inf;
		%END;

	if substr(atc,1,4)="A10B" and laji="K" and &AVUOSI<2017 and &LVUOSI>=2017 then laji="Y";
	if substr(atc,1,4)="A10B" and laji="Y" and &AVUOSI>=2017 and &LVUOSI<2017 then laji="K";

	RUN;

/* Taksan laskenta, suoritetaan vain tarvittaessa */

%IF &TAKSAT = 1 %THEN %DO;

DATA TEMP.&TULOSNIMI_LA;
SET TEMP.&TULOSNIMI_LA;
	%LaakTaksaVMH(VMH_SIMU, &LVUOSI, &LKUUK, &INF);
RUN;
/* Jaetaan nelj��n kauteen ja lasketaan kaikille erikseen viitehinta */

DATA viitehinnat;
	SET TEMP.&TULOSNIMI_LA;
	KAUSI=.; * T�m� t�ytyy poistaa ennen, koska muuttuja olemassa etuk�teen datassa;
	IF MONTH(VOALPV)=1 AND DAY(VOALPV)=1 THEN KAUSI=1;
	IF MONTH(VOALPV)=4 AND DAY(VOALPV)=1 THEN KAUSI=2;
	IF MONTH(VOALPV)=7 AND DAY(VOALPV)=1 THEN KAUSI=3;
	IF MONTH(VOALPV)=10 AND DAY(VOALPV)=1 THEN KAUSI=4;
	IF KAUSI ^=.;
	IF VMH_SIMU^=.;
	IF VIHINTA>0 AND SUBKOODI^="";
	KEEP VMH_SIMU SUBKOODI VNRON KAUSI;
RUN;
/* Poistan duplikaatit, jos niit� on */
proc sort data=viitehinnat nodup; by SUBKOODI VNRON KAUSI VMH_SIMU;run;
proc sort data=viitehinnat nodup; by KAUSI SUBKOODI VMH_SIMU;run;


data viitehinnat2;
	set viitehinnat;
	by KAUSI SUBKOODI;
	%LaakViiteHinta(VIHINTA_SIMU, &LVUOSI, &LKUUK, &INF);

	drop VNRON VMH_SIMU;
run;


proc sort data=viitehinnat2;by SUBKOODI KAUSI;run;
proc sort data=TEMP.&TULOSNIMI_LA;by SUBKOODI KAUSI;run;

DATA TEMP.&TULOSNIMI_LA;
merge TEMP.&TULOSNIMI_LA viitehinnat2; 
by SUBKOODI KAUSI; 

	%LaakTaksa(KUST_SIMUL, &LVUOSI, &LKUUK, &INF);
IF HNRO>0;
RUN;



/* Kertym� pit�� viel� laskua RVMK:sta */
PROC SORT DATA = TEMP.&TULOSNIMI_LA;
	BY hnro otpvm LAJI_NUM rvmk_SIMU; RUN;
DATA TEMP.&TULOSNIMI_LA;
	SET TEMP.&TULOSNIMI_LA;
	BY hnro otpvm LAJI_NUM rvmk_SIMU;
	/* RVMK:n kertym�, tarvitaan etenkin alkuomavastuun laskennassa */
	RETAIN RVMK_KERTY_SIMU;
	IF first.hnro THEN RVMK_KERTY_SIMU=rvmk_SIMU;
		ELSE DO;
			RVMK_KERTY_SIMU=RVMK_KERTY_SIMU+rvmk_SIMU;
		END;
run;
%END;

%IF &TAKSAT NE 1 %THEN %DO;
	DATA TEMP.&TULOSNIMI_LA;
			SET TEMP.&TULOSNIMI_LA;
			KUST_SIMUL=KUST;
			RVMK_SIMU=RVMK;
			RVMK_KERTY_SIMU=RVMK_KERTY;
	RUN;
%END;



proc sort data=TEMP.&TULOSNIMI_LA;by hnro otpvm laji_num rvmk_simu; run;
/* Alkuomavastuun laskenta */
DATA TEMP.&TULOSNIMI_LA;
SET TEMP.&TULOSNIMI_LA;
	BY hnro otpvm LAJI_NUM rvmk_simu;
	%LaakAlkuOmaVastuu(ALKUOMAV_SIMUL, &LVUOSI, &LKUUK, &INF, ika, rvmk_simu, rvmk_kerty_SIMU);

	/* N�iden korvaukset prosenttiperusteisia, eli peruskorvaus, rajoitettu peruskorvaus ja alempi erityiskorvausoikeus */
	IF laji IN ("O","U","Y")
		THEN DO;
			%LaakKorvausPros(KORV_SIMUL, &LVUOSI, &LKUUK, &INF, laji);
			%LaakResOmavastuuPros(ROMAV_SIMUL, &LVUOSI, &LKUUK, &INF, laji);
		END;
		/* Ylempi erityiskorvaus on euro-perusteinen */
		ELSE IF laji IN ("K") 
			THEN DO;
				%LaakResOmavastuuEuro(ROMAV_SIMUL, &LVUOSI, &LKUUK, &INF, laji);
				%LaakKorvausEuro(KORV_SIMUL, &LVUOSI, &LKUUK, &INF, laji);
			END;
	/* Lis�t��n alkuomavastuu reseptin omavastuuseen */
	ROMAV_SIMUL=ALKUOMAV_SIMUL + ROMAV_SIMUL;
RUN;
/* Reseptin omavastuun kertym�n laskeminen, onnistuu vain aiempien j�lkeen */

proc sort data=temp.&TULOSNIMI_LA; by hnro otpvm ostos;run;
DATA TEMP.&TULOSNIMI_LA;
	SET TEMP.&TULOSNIMI_LA;
	BY hnro otpvm ostos;
	retain ROMAV_KERTY_SIMUL;
	if first.hnro then ROMAV_KERTY_SIMUL=ROMAV_SIMUL;else ROMAV_KERTY_SIMUL=ROMAV_KERTY_SIMUL + ROMAV_SIMUL;

	%LaakKattoKorvausMaksettava(LAAKEIV_SIMUL, &LVUOSI, &LKUUK, &INF);
	if YLI_KATTO_CUMU >= 1 then KAKORV_SIMUL = ROMAV_SIMUL - LAAKEIV_SIMUL;else KAKORV_SIMUL=0;
	LISAOMAV_SIMUL = round(SUM(KUST_SIMUL, -KORV_SIMUL, -KAKORV_SIMUL, -LAAKEIV_SIMUL), 0.01);
	if KAKORV_SIMUL < 0 then LISAOMAV_SIMUL = LISAOMAV_SIMUL - KAKORV_SIMUL;
	KORV_LISAK_SIMUL = KORV_SIMUL + KAKORV_SIMUL;
	LAAKE_SIMUL = LAAKEIV_SIMUL + LISAOMAV_SIMUL;
	IF JTJNO>0 THEN LAAKE_DATA=SUM(-kakorv,kust,-rvmk);
	ELSE LAAKE_DATA=SUM(romav,-kakorv,kust,-rvmk);

	/*Lis�t��n labelit t�h�n */
	label KORV_SIMUL = "Korvaus ilman kattokorvausta, malli" 
		KAKORV_SIMUL = "Kattokorvaus, malli"
		ROMAV_SIMUL = "Reseptin omavastuu huomioimatta kattokorvausta, malli"
		LAAKEIV_SIMUL = "Asiakkaan maksuosuus ilman viitehinnan ylitt�v�� osuutta, malli"
		LAAKE_SIMUL = "Asiakkaan maksuosuus viitehinnan ylitt�v�n osuuden kanssa, malli"
		LAAKE_DATA = "Asiakkaan maksuosuus viitehinnan ylitt�v�n osuuden kanssa, DATA"
		LISAOMAV_SIMUL = "Asiakkaan lis�omavastuu (viitehinnan ylitt�v� osuus), malli"
		KORV_LISAK_SIMUL = "Korvaus + kattokorvaus, malli"
		;
	
run;

/*%IF &START = 1 %THEN %DO;*/
	proc summary data=temp.&tulosnimi_la NWAY; id ykor;
		class hnro;
		output out=temp.&tulosnimi_la(DROP=_type_ _freq_)
		sum(LAAKE_SIMUL LAAKEIV_SIMUL KORV_SIMUL KAKORV_SIMUL LAAKE_DATA) =;
	run;
/*%END;*/
/*%ELSE %IF &TULOKSET = 1 %THEN %DO;
PROC MEANS DATA=TEMP.&TULOSNIMI_LA N MEAN MIN MAX STD SUM;	VAR KORV KORV_SIMUL ROMAV ROMAV_SIMUL KUST KUST_SIMUL LAAKEIV_SIMUL KAKORV KAKORV_SIMUL 
	KORV_LISAK_SIMUL laake_SIMUL RVMK RVMK_SIMU LISAOMAV_SIMUL; OUTPUT OUT=TULOKSET1;
run;
PROC SUMMARY DATA= TEMP.&TULOSNIMI_LA NWAY; CLASS HNRO; OUTPUT OUT=TEMP.&TULOSNIMI_LA(DROP=_type_ _freq_) SUM(KORV KORV_SIMUL ROMAV ROMAV_SIMUL KUST KUST_SIMUL LAAKEIV_SIMUL KAKORV KAKORV_SIMUL 
	KORV_LISAK_SIMUL laake_SIMUL RVMK RVMK_SIMU LISAOMAV_SIMUL)= KORV KORV_SIMUL ROMAV ROMAV_SIMUL KUST KUST_SIMUL LAAKEIV_SIMUL KAKORV KAKORV_SIMUL 
	KORV_LISAK_SIMUL laake_SIMUL RVMK RVMK_SIMU LISAOMAV_SIMUL; RUN;
 
%END;*/

%MEND Laake_Simuloi_Data;

%Laake_Simuloi_Data;

%LET loppui2&malli = %SYSFUNC(TIME());

%MACRO KutsuTulokset;
	
	%IF &TULOKSET = 1 AND &YKSIKKO = 1 %THEN %DO;
		%KokoTulokSET(1,&MALLI,TEMP.&TULOSNIMI_LA,1);
	%END;
	%IF &TULOKSET = 1 AND &YKSIKKO = 2 %THEN %DO;
		%KokoTulokSET(1,&MALLI,TEMP.&TULOSNIMI_LA,2);
	%END;

	/* Jos EG = 1 ja simulointia ei ajettu KOKOsimul-koodin kautta, palautetaan EG-makromuuttujalle oletusarvo */
	%IF &START ^= 1 and &EG = 1 %THEN %DO;
		%LET EG = 0;
	%END;
%MEND;
%KutsuTulokset;


%LET loppui1&malli = %SYSFUNC(TIME());

%LET kului1&malli = %SYSEVALF(&&loppui1&malli - &&alkoi1&malli);

%LET kului2&malli = %SYSEVALF(&&loppui2&malli - &&alkoi2&malli);

%LET kului1&malli = %SYSFUNC(PUTN(&&kului1&malli, time10.2));

%LET kului2&malli = %SYSFUNC(PUTN(&&kului2&malli, time10.2));

%PUT &malli. Koko laskenta. Aikaa kului (hh:mm:ss.00) &&kului1&malli;

%PUT &malli. Varsinainen simulointi. Aikaa kului (hh:mm:ss.00) &&kului2&malli;
