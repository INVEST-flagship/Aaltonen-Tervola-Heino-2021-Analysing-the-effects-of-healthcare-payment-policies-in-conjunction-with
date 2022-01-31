
%TuhoaGlobaalit;

%LET START = &OUT;
%LET MALLI = ASMAKSU;

%LET KATTONRO=0; *Simuloidaanko kattoyksikkö (eli kumman vanhemman maksukattoon lapsi kuuluu);

%LET alkoi1&MALLI = %SYSFUNC(TIME());

%MACRO Aloitus;

%IF &START = 1 %THEN %DO;
	%LET TYYPPI = &TYYPPI_KOKO;
	%LET TULOKSET = 0;
%END;

%IF &START NE 1 %THEN %DO;
	/* Seuraavia vaiheita ei ajeta jos arvot annetaan tämän koodin ulkopuolelta (&EG = 1) */

	%IF &EG NE 1 %THEN %DO;

	%LET AVUOSI = 2017;		* Aineistovuosi (vvvv);

	%LET MAKSUTASO=KUNTA;	* Käytetäänkö lakisääteisiä enimmäismääriä (TYHJÄ) vai vuoden 2017 kuntatasoja (2017);

	%LET LVUOSI = 2020;		* Lainsäädäntövuosi (vvvv);

	%LET TYYPPI = SIMUL;	* Parametrien hakutyyppi: SIMUL (vuosikeskiarvo) tai SIMULX (parametrit haetaan tietylle kuukaudelle);

	%LET LKUUK = 12;		* Lainsäädäntökuukausi, jos parametrit haetaan tietylle kuukaudelle;
							* Huomaa kuitenkin, että asumislisän laskemisessa käytetään oletuksena sekä lainsäädäntövuoden alun
							  että lopun parametriarvoja;

	%LET AINEISTO = REK;	* Käytettävä aineisto (PALV = Palveluaineisto, REK = Rekisteriaineisto) ;

	%LET TULOSNIMI_AS = asmaksu_output_katto; * Simuloidun tulostieDOston nimi ;

	%LET INF = 1.00; * Syötä lukuarvo, KHI tai ATI;
	%LET PINDEKSI_VUOSI = pindeksi_vuosi; *Käytettävä indeksien parametritaulukko;


	%LET POIMINTA = 0;  	* Muuttujien poiminta (1 jos ajetaan, 0 jos ei);
	%LET TULOKSET = 0;		* Yhteenvetotaulukot (1 jos ajetaan, 0 jos ei);

	%LET LAKIMAK_TIED_AS = ASMAKSUlakimakrot_kunta21kun;* Lakimakrotiedoston nimi ;
	%LET PASMAKSU = pasmaksu2021; * Käytettävän parametritiedoston nimi ;

	* Tulostaulukoiden esivalinnat ; 

	%LET TULOSLAAJ = 1 ; 	 * Mikrotason tulosaineiston laajuus (1 = suppea, 2 = laaja (kaikki pohja-aineiston muuttujat)) ;
	%LET MUUTTUJAT =  ASMA_YHT; * Taulukoitavat muuttujat (summataulukot) ;
	%LET YKSIKKO = 1;		 * Tulostaulukoiden yksikkö (1 = henkilö, 2 = kotitalous) ;
	%LET LUOK_HLO1 = laji2; * Taulukoinnin 1. henkilöluokitus (jos YKSIKKO = 1)
							   Vaihtoehtoina: 
							     desmod (tulodesiilit, ekvivalentit tulot (modoecd), hlöpainot)
							     ikavu (henkilön mukaiset ikäryhmät)
							     elivtu (kotitalouden elinvaihe)
							     koulas (henkilön koulutusaste TK1997)
							     soss (henkilön sosioekonominen asema AML2001)
							     rake (kotitalouden rakenne)
								 maakunta (NUTS3-aluejaon mukainen maakuntajako);
	%LET LUOK_HLO2 = ;		 * Taulukoinnin 2. henkilöluokitus ;
	%LET LUOK_HLO3 = ;		 * Taulukoinnin 3. henkilöluokitus ;

	%LET LUOK_KOTI1 = ; * Taulukoinnin 1. kotitalousluokitus (jos YKSIKKO = 2) 
							    Vaihtoehtoina: 
							     desmod (tulodesiilit, ekvivalentit tulot (moDOecd), hlöpainot)
							     ikavuV (viitehenkilön mukaiSET ikäryhmät)
							     elivtu (kotitalouden elinvaihe)
							     koulas (viitehenkilön koulutusaste TK1997)
							     paasoss (kotitalouden sosioekonominen asema AML2001)
							     rake (kotitalouden rakenne)
								 maakunta (NUTS3-aluejaon mukainen maakuntajako);
	%LET LUOK_KOTI2 = ; 	  * Taulukoinnin 2. kotitalousluokitus ;
	%LET LUOK_KOTI3 = ; 	  * Taulukoinnin 3. kotitalousluokitus ;

	%LET EXCEL = 0; 		 * Viedäänkö tulostaulukko automaattisesti Exceliin (1 = Kyllä, 0 = Ei) ;

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

	%END;

	/* Lasketaan mahDOllinen indeksiin perustuva inflaatiokorjaus */

	%InfKerroin(&AVUOSI, &LVUOSI, &INF);

%END;

/* Ajetaan lakimakrot ja tallennetaan ne */

%INCLUDE "&LEVY&KENO&HAKEM&KENO.MAKROT&KENO&LAKIMAK_TIED_AS..sas";

%MEND;

%Aloitus;

%MACRO ASMAKSU_Muutt_Poiminta;

%IF &POIMINTA = 1 %THEN %DO;
	DATA STARTDAT.START_ASMAKSU; 	
		SET pohjadat.&AINEISTO&AVUOSI(KEEP=hnro htperhe hrelake kelapu ykor knro kuntakoodi jasen puoliso jasenia ikavu ikakk svatva svatvp tnoosvvb teinovvb tuosvvap toyjmyvvap toyjmavvap teinovv verot lpvma lveru ltvp tkopira tkotihtu riyl);

		BRUTTOTULOT_DATA = ROUND( SUM(svatva, svatvp, kelapu, tnoosvvb, teinovvb, tuosvvap, toyjmyvvap, toyjmavvap, teinovv, riyl, -tkopira, -tkotihtu)/12);
		IF svatva THEN ANSIOVEROPROS= SUM(verot, -lpvma, lveru, -ltvp) / svatva;
		NETTOTULOT_DATA = ROUND( SUM(BRUTTOTULOT_DATA,-SUM(verot, -lpvma, lveru)/12, ANSIOVEROPROS* SUM(tkopira, tkotihtu)/12));

		KEEP hnro knro jasen ykor puoliso jasenia ikavu ikakk kuntakoodi BRUTTOTULOT_DATA NETTOTULOT_DATA;
		RUN;

	
	PROC SORT DATA=STARTDAT.START_ASMAKSU OUT=TEMP.PUOLTULOT(keep=hnro knro puoliso NETTOTULOT_DATA BRUTTOTULOT_DATA); WHERE puoliso; BY knro puoliso;
	PROC SORT DATA=STARTDAT.START_ASMAKSU; BY knro jasen; RUN;

	DATA STARTDAT.START_ASMAKSU;
	MERGE STARTDAT.START_ASMAKSU(in=a) 
	TEMP.PUOLTULOT(RENAME=(nettoTULOT_DATA=PUOLNETTOTULOT_DATA bruttoTULOT_DATA=PUOLBRUTTOTULOT_DATA puoliso=jasen hnro=puolhnro)); 
	BY knro jasen;

	DROP puoliso jasen;
	RUN;

	PROC SORT DATA=STARTDAT.START_ASMAKSU; BY hnro; RUN;
	PROC SORT DATA=POHJADAT.ASMAKSU&AVUOSI; BY hnro; RUN;

	DATA STARTDAT.START_ASMAKSU; 
	merge POHJADAT.ASMAKSU&AVUOSI(IN=A keep=hnro laji2 psyk pitkapaatos laakari hoitopv hoitopv&avuosi alku loppu kustannus lasupyh_yo alle18kerty %IF &kattonro=0 %THEN %DO; kattonro %END; lyhhoito30 laitos tk_makkerrat) STARTDAT.START_ASMAKSU(IN=B); 
	BY hnro; 
	IF A AND B;
	/*IF laji2>4 THEN DO; BRUTTOTULOT_DATA=.; NETTOTULOT_DATA=.; PUOLNETTOTULOT_DATA=.; PUOLBRUTTOTULOT_DATA=.; END;*/

	if year(alku)=&AVUOSI THEN ika = ROUND(ikavu+ikakk/12-(12-month(alku))/12,0.01);
	ELSE ika=ikavu+ikakk/12-1;

	IF A THEN KK=MONTH(ALKU);

	KUNTANRO=INPUT(KUNTAKOODI,BEST21.);
		
	DROP ikavu ikakk LOPPU KUNTAKOODI;

	RUN;



	%IF &MAKSUTASO=KUNTA %THEN %DO;
			PROC SORT DATA=STARTDAT.START_ASMAKSU;BY KUNTANRO; PROC SORT DATA=PARAM.KUNTASHP; BY KUNTANRO;
			DATA STARTDAT.START_ASMAKSU; MERGE STARTDAT.START_ASMAKSU(IN=A) PARAM.KUNTASHP; BY KUNTANRO; 
			IF A;
			RUN;
	%END;
%END;
PROC SORT DATA=STARTDAT.START_ASMAKSU; BY KATTONRO alku; RUN;	



%MEND;

%ASMAKSU_Muutt_Poiminta;

%LET alkoi2&malli = %SYSFUNC(TIME());

%MACRO ASMAKSU_OsaMallit;

%IF &VERO = 1 AND &KANSEL=1 %THEN %DO;


	PROC SORT DATA=STARTDAT.START_ASMAKSU; BY HNRO;

	DATA STARTDAT.START_ASMAKSU(DROP= ANSIOVEROPROS ANSIOT POTULOT OPTUKI_SIMUL KOTIHTUKI_SIMUL OSINKOVAP PRAHAMAKSU PALKVAK ANSIOVEROT POVEROC YLEVERO); 
	MERGE STARTDAT.START_ASMAKSU(IN=A)

	TEMP.&TULOSNIMI_VE(KEEP = hnro ANSIOT POTULOT OPTUKI_SIMUL KOTIHTUKI_SIMUL
		OSINKOVAP PRAHAMAKSU PALKVAK ANSIOVEROT POVEROC YLEVERO) 

	TEMP.&TULOSNIMI_KE(KEEP = hnro YLIMRILI EHOITUKI); 

	BY hnro; 
	IF a;
	
	IF laji2<7 THEN DO; 
		BRUTTOTULOT_SIMUL = SUM(ANSIOT, POTULOT, OSINKOVAP, YLIMRILI, EHOITUKI, -OPTUKI_SIMUL, -KOTIHTUKI_SIMUL)/12;
		IF ANSIOT THEN ANSIOVEROPROS= ANSIOVEROT / ANSIOT;
		NETTOTULOT_SIMUL = SUM(BRUTTOTULOT_SIMUL,-SUM(PRAHAMAKSU,PALKVAK,ANSIOVEROT,POVEROC,YLEVERO)/12, ANSIOVEROPROS* SUM(OPTUKI_SIMUL, KOTIHTUKI_SIMUL)/12);
	END;
	RUN; 

	PROC SORT DATA=STARTDAT.START_ASMAKSU; BY puolhnro;

	DATA STARTDAT.START_ASMAKSU(DROP= ANSIOVEROPROS ANSIOT POTULOT OPTUKI_SIMUL KOTIHTUKI_SIMUL OSINKOVAP PRAHAMAKSU PALKVAK ANSIOVEROT POVEROC YLEVERO); 
	MERGE STARTDAT.START_ASMAKSU(IN=A) 

	TEMP.&TULOSNIMI_VE(KEEP= hnro ANSIOT POTULOT OPTUKI_SIMUL KOTIHTUKI_SIMUL
		OSINKOVAP PRAHAMAKSU PALKVAK ANSIOVEROT POVEROC YLEVERO RENAME=(hnro=puolhnro))

	TEMP.&TULOSNIMI_KE(KEEP = hnro YLIMRILI EHOITUKI RENAME=(hnro=puolhnro)); 

	BY puolhnro; 
	IF a;
	
	IF laji2<7 THEN DO;
		PUOLBRUTTOTULOT_SIMUL = SUM(ANSIOT, POTULOT, OSINKOVAP,  YLIMRILI, EHOITUKI, -OPTUKI_SIMUL, -KOTIHTUKI_SIMUL)/12;
		IF ANSIOT THEN ANSIOVEROPROS= ANSIOVEROT / ANSIOT;
		PUOLNETTOTULOT_SIMUL = SUM(PUOLBRUTTOTULOT_SIMUL,-SUM(PRAHAMAKSU,PALKVAK,ANSIOVEROT,POVEROC,YLEVERO)/12, ANSIOVEROPROS* SUM(OPTUKI_SIMUL, KOTIHTUKI_SIMUL)/12);
	END;
	RUN;
%END;

%IF &kattonro=0 AND (&poiminta=1 OR &VERO=1) %THEN %DO; %END;
%MEND;

%ASMAKSU_OsaMallit;




%MACRO ASMAKSU_Simuloi_DATA;
%LOCAL ASMAKSU_PARAM ASMAKSU_MUUNNOS;

%HaeLokaalit(ASMAKSU_PARAM, ASMAKSU);
%HaeLaskettavatLokaalit(ASMAKSU_MUUNNOS, ASMAKSU);

%LOCAL &ASMAKSU_PARAM;
%KuukSimul(ASMAKSU);

%IF &VERO=1 %THEN %LET PAATE =SIMUL;
%ELSE %LET PAATE = DATA;


DATA TEMP.&TULOSNIMI_AS; SET STARTDAT.START_ASMAKSU;


/*IF laji2 =1 THEN DO;
	%LaitosHoito(PITKLAITOSMAKSU,&LVUOSI,&LKUUK,&INF,ika,laji2,nettotulot_&paate,puolnettotulot_&paate,0,0,psyk=psyk);

	PITKLAITOSMAKSU = ROUND(PITKLAITOSMAKSU * hoitopv&AVUOSI/30,0.01);
END;

*Kotihoito;
ELSE IF laji2 IN (4,41,42) THEN DO;
	%KotiHoito&MaksuTaso(KOTIHTULOSM,&LVUOSI,&LKUUK,&INF,hoitopv&AVUOSI,jasenia,hoitopv,sum(bruttotulot_&paate,puolbruttotulot_&paate),laakari,saannol=pitkapaatos);
	IF hoitopv&AVUOSI < 18 AND pitkapaatos NE 1 AND laji2 = 41 THEN DO;
		
		TASAMAKSU = KOTIHTULOSM;
		KOTIHTULOSM=.;
	END;
	laji2=4;
END;

*Palveluasuminen;
/*ELSE IF laji2 =2 and (pitkapaatos or hoitopv>60) THEN DO;
	%LaitosHoito(PITKLAITOSMAKSU,&LVUOSI,&LKUUK,&INF,ika,laji2,nettotulot_&paate,puolnettotulot_&paate,vuokra2,omav_laake,psyk=psyk);

	PITKLAITOSMAKSU=round((hoitopv&AVUOSI/30.5)*PITKLAITOSMAKSU);
END;*/


*Lyhyt laitoshoito (ml. kuntoutushoito);
 IF laji2 IN (5,6) THEN DO;
	%LaitosHoito(TASAMAKSU,&LVUOSI,&LKUUK,&INF,ika,laji2,0,0,0,0,psyk=psyk);
	

	*Alle 18-vuotiaiden välikaton huomiointi;
	IF laji2=5 AND SUM(alle18kerty, -hoitopv&avuosi) > &LyhytaikMaxPV THEN TASAMAKSU = 0;
	ELSE IF laji2 = 5 AND alle18kerty > &LyhytaikMaxPV THEN TASAMAKSU = &LyhytaikMaxPV * TASAMAKSU; 

	ELSE TASAMAKSU = ROUND(TASAMAKSU * hoitopv&AVUOSI,0.01);

END;

*Kaikki avohoidon maksut (pl. suun terveydenhuolto);
ELSE IF 6<laji2<13 OR laji2=27 THEN DO;
	%AvoHoito&MaksuTaso(TASAMAKSU,&LVUOSI,&LKUUK,&INF,ika,laji2,hoitopv&AVUOSI,hoitopv,psyk,lasupyh_yo,vuosimaksu=(tk_makkerrat=1));
	laji2=floor(laji2);
END;

*Suun terveydenhuollon maksut;
ELSE IF 13<=laji2<27 THEN DO;
	%AvoHoito&MaksuTaso(TASAMAKSU,&LVUOSI,&LKUUK,&INF,ika,laji2,hoitopv&AVUOSI,0,0,0,laakari=laakari);
	laji2=26;
END;


*Ajetaan jos maksukaton yksilöivä tunnus simuloidaan uudestaan maksukertymän mukaan (vanhemmalle jolla eneiten maksuja);
%IF &KATTONRO=1 %THEN %DO;

	RUN;
	%include "&LEVY&KENO&HAKEM&KENO.DATA&KENO.POHJADAT&KENO.HILMO_datamuok.sas";
	%KATTONRO(&AVUOSI);

	%GOTO EXIT;

%END;


*Maksukaton sovellus;
BY kattonro;

IF first.kattonro then KERTYMA=0;

%if &lvuosi>=2021 %then %do; IF 4<= laji2 <=27  then DO; %end;
%else %do; IF 4< laji2 < 13 OR laji2=27  then DO; %end;

	KERTYMA + TASAMAKSU;

	%MaksuKatto(KATON_JALKEEN, &LVUOSI, &LKUUK, &INF, laji2, ika, TASAMAKSU, KERTYMA, hoitopv&AVUOSI,erikoissh=(psyk NE .));

	KATTO_TAYNNA= (TASAMAKSU AND ROUND(TASAMAKSU,0.01) NE ROUND(KATON_JALKEEN,0.01));
	TASAMAKSU = KATON_JALKEEN;

END;
ELSE KATTO_TAYNNA=0;

ARRAY PISTE 
TASAMAKSU;
DO OVER PISTE;
	IF PISTE <= 0 THEN PISTE = .;
END;
%IF &MAKSUTASO=KUNTA %THEN %DO; DROP LYHYTAIKLAITOSPTH--SARJAHOITOKERTA; %END;

ASMA_YHT=ROUND( tasamaksu,0.01);
IF laji2=26 THEN DO; JULKSUUNTH=tasamaksu; tasamaksu=.; END;

LABEL 
KOTIHTULOSM="Kotihoidon tulosidonnaiset maksut"
TASAMAKSU="Tasasuuruiset maksut";
TEHOPALVAS="Tehostetun palveluasumisen maksut";
PITKLAITOSMAKSU="Pitkäaikaisen laitoshoidon maksut";

RUN;

%IF &START NE 1 %THEN %DO;

PROC SUMMARY DATA= TEMP.&TULOSNIMI_AS NWAY; CLASS HNRO; ID YKOR; OUTPUT OUT=TEMP.&TULOSNIMI_AS(DROP=_type_ _freq_) SUM(&MUUTTUJAT)= MAX(KATTO_TAYNNA)=; RUN;

	* Yhdistetään tulokset pohja-aineistoon;

	DATA TEMP.&TULOSNIMI_AS;
		
	* 3.2.1 Suppea tulostiedosto (vain tärkeimmät luokittelumuuttujat);

	%IF &TULOSLAAJ = 1 %THEN %DO; 
		MERGE POHJADAT.&AINEISTO&AVUOSI 
		(KEEP = hnro knro &PAINO desmod ikavu elivtu)
		TEMP.&TULOSNIMI_AS;
	%END;

	* 3.2.2 Laaja tulostiedosto (kaikki pohja-aineiston muuttujat);

	%IF &TULOSLAAJ = 2 %THEN %DO; 
		MERGE POHJADAT.&AINEISTO&AVUOSI TEMP.&TULOSNIMI_AS;
	%END;

	* Asetetaan muuttujien 0-arvot tyhjiksi, jotta lukumäärät voidaan laskea suoraan ;

	BY hnro;
	*perusterv=(psyk=.);
	yli65v=(ikavu>65);

	RUN;


	%IF &YKSIKKO = 2 AND &START ^= 1 %THEN %DO;
		%SumKotitT(OUTPUT.&TULOSNIMI_AS._KOTI, TEMP.&TULOSNIMI_AS, &MALLI, &MUUTTUJAT);

		PROC DATASETS LIBRARY=TEMP NOLIST;
			DELETE &TULOSNIMI_AS;
		RUN;
		QUIT;
	%END;
	%ELSE %DO;

		PROC DATASETS LIBRARY=TEMP NOLIST;
			DELETE &TULOSNIMI_AS._HLO;
			CHANGE &TULOSNIMI_AS=&TULOSNIMI_AS._HLO;
			COPY OUT=OUTPUT MOVE;
			SELECT &TULOSNIMI_AS._HLO;
		RUN;
		QUIT;
	%END;

	* Tyhjennetään TEMP-kirjasto ;

	%IF &TEMPTYHJ = 1 %THEN %DO;
		PROC DATASETS LIBRARY=TEMP NOLIST KILL;
		RUN;
		QUIT;
	%END;

%END;
%ELSE %DO;
	%IF &TOTUTASO=KK  %THEN %DO; PROC SUMMARY DATA= TEMP.&TULOSNIMI_AS NWAY; CLASS HNRO KK; OUTPUT OUT=TEMP.&TULOSNIMI_AS._KK(DROP=_type_ _freq_ WHERE=(MAX(tasamaksu, LAITOS)>0)) SUM(tasamaksu)= MAX(LYHHOITO30 LAITOS)=; RUN; %END;
	PROC SUMMARY DATA= TEMP.&TULOSNIMI_AS NWAY; CLASS HNRO; OUTPUT OUT=TEMP.&TULOSNIMI_AS(DROP=_type_ _freq_ WHERE=(MAX(tasamaksu, LAITOS)>0)) SUM(tasamaksu julksuunth)= MAX(LYHHOITO30 LAITOS)=; RUN;
%END;

%EXIT: %MEND;

%ASMAKSU_Simuloi_DATA;

%LET loppui2&malli = %SYSFUNC(TIME());

%MACRO KutsuTulokset;
%IF &KATTONRO NE 1 %THEN %DO;	
	%IF &TULOKSET = 1 AND &YKSIKKO = 1 %THEN %DO;
		%KokoTulokSET(1,&MALLI,TEMP.&TULOSNIMI_AS,1);
	%END;
	%IF &TULOKSET = 1 AND &YKSIKKO = 2 %THEN %DO;
		%KokoTulokSET(1,&MALLI,TEMP.&TULOSNIMI_AS._KOTI,2);
	%END;

	/* Jos EG = 1 ja simulointia ei ajettu KOKOsimul-koodin kautta, palautetaan EG-makromuuttujalle oletusarvo */
	%IF &START ^= 1 and &EG = 1 %THEN %DO;
		%LET EG = 0;
	%END;
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



