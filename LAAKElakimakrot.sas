/********************************************************
* Kuvaus: L‰‰kekorvauksien lains‰‰d‰ntˆ‰ makroina       *
* Viimeksi p‰ivitetty: 11.9.2019                        *
********************************************************/

/* SOTE-SISUA varten tehdyt SAS-makrot                     */
/* K‰‰nnetty R:n laakesimufunk-paketista SAS:iin           */
/* Pekka Heino 11.9.2019                                   */

/* Tiedosto sis‰lt‰‰ seuraavat makrot:

1. LaakAlkuOmaVastuu = L‰‰kkeiden alkuomavastuun laskukaava
2. LaakKorvausEuro = L‰‰kkeiden korvausten laskukaava (ei kattokorvausta), eurom‰‰r‰inen alkuomavastuu
3. LaakResOmaVastuuEuro = L‰‰kkeiden reseptin omavastuun laskukaava, eurom‰‰r‰inen alkuomavastuu
4. LaakKorvausPros = L‰‰kkeiden korvausten laskukaava (ei kattokorvausta), prosenttiperusteinen alkuomavastuu
5. LaakResOmaVastuuPros = L‰‰kkeiden reseptin omavastuun laskukaava, prosenttiperusteinen alkuomavastuu
6. LaakKattoKorvaus = L‰‰kkeiden kattokorvausten laskukaava
7. LaakTaksa = L‰‰kkeiden taksojen laskukaava (EI VALMIS) */

/* Koodissa n‰it‰ yleens‰ k‰ytet‰‰n j‰rjestyksess‰ 7, 1, (2, 3) tai (4, 5), 6 . Tosin ensimm‰isi‰ ei ole pakko
suorittaa, jos niihin ei tee muutoksia. */

/* 1. Makro, joka laskee alkuomavastuun m‰‰r‰n kyseisen oston kohdalla */
/* Jotta makro toimisi oikein, pit‰‰ datan olla j‰rjestettyn‰ valmiiksi seuraavien muuttujien mukaan:
ID, OTPVM, LAJI_NUM, RVMK */
*Makron parametrit:
	tulos: Makron tulosmuuttuja, alkuomavastuun m‰‰r‰
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	mkuuk: Kuukausi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	ikaraj: Ik‰
	rvmk: Rvmk
	rvmk_k: Rvmk-kertym‰
	;

%MACRO LaakAlkuOmaVastuu(tulos, mvuosi, mkuuk, minf, ikaraj, rvmk, rvmk_k)/
DES = 'LAAKE: Alkuomavastuun m‰‰r‰ l‰‰kkeen kohdalla';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	*%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);

	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
* Lasketaan ketk‰ ylitt‰v‰t alkuomavastuun;
	RETAIN OVAL_CUMU;
	IF &rvmk_k >= &AlkuomavTaso1 
		THEN OVAL=1;
		ELSE OVAL=0;
	IF &ikaraj < &AlkuomavIkaraja1 
		THEN OVAL=0;
* Lasketaan, kuinka monta ostosta on yli alkuomavastuun (OVAL_CUMU=1 on rajaosto);
/* Jos data on j‰rjestetty ennen makron suorittamista, ei j‰rjest‰mist‰ tarvitse tehd‰ */
	IF first.hnro THEN DO;
		OVAL_CUMU=0;
	  END;
	OVAL_CUMU = OVAL_CUMU + OVAL;
	* Lasketaan alkuomavastuun m‰‰r‰;
	IF OVAL=0 THEN &tulos = &rvmk;
		ELSE &tulos = 0;
	IF OVAL_CUMU=1 THEN &tulos = &AlkuomavTaso1 - (&rvmk_k - &rvmk);
	/* Ik‰raja, mink‰ alle ei ole omavastuuta. Vuoden lopun i‰n mukaan, kuten laissakin on */
	IF &ikaraj <= &AlkuomavIkaraja1 THEN &tulos = 0;
	* Jos OVAL_CUMU > 1, ei alkuomavastuuta ;
	*&tulos = ALKUOMAV_SIMUL;
%MEND LaakAlkuOmaVastuu;

/* 2. Makro, joka laskee l‰‰kkeen korvauksen m‰‰r‰n (ilman kattokorvausta) kyseisen oston kohdalla */

*Makron parametrit:
	tulos: Makron tulosmuuttuja, korvauksen m‰‰r‰
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	mkuuk: Kuukausi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	klaji: L‰‰kelaji;

%MACRO LaakKorvausEuro(tulos, mvuosi, mkuuk, minf, klaji)/
DES = 'LAAKE: Korvauksen m‰‰r‰ (ilman kattokorvausta) l‰‰kkeen kohdalla, eurom‰‰r‰inen omavastuu';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);
	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
	/* Kokonaan alle alkuomavastuun olevissa l‰‰kkeiss‰ korvaus = 0 */
	IF OVAL_CUMU = 0 THEN &tulos = 0;
	/* Rajaoston kohdalla osa on korvattavaa ja osa alkuomavastuun piiriss‰ */
	ELSE IF OVAL_CUMU = 1 AND ANJA = "" AND ika > &AlkuomavIkaraja1 THEN DO;
		IF RVMK_KERTY_SIMU - &AlkuomavTaso1 >= &YlempiEritKorvKiintea THEN DO;
			&tulos = RVMK_KERTY_SIMU - &AlkuomavTaso1 - &YlempiEritKorvKiintea;
		END;
		ELSE IF RVMK_KERTY_SIMU - &AlkuomavTaso1 < &YlempiEritKorvKiintea THEN DO;
			&tulos = 0;
		END;
	END;

	/* 18-vuotiaaksi saakka kaikki ovat korvattavia */
	ELSE IF (OVAL_CUMU > 1 OR ika <= &AlkuomavIkaraja1) AND ANJA = "" THEN DO;
		IF rvmk_SIMU < &YlempiEritKorvKiintea THEN &tulos = 0;
		ELSE IF rvmk_SIMU >= &YlempiEritKorvKiintea THEN &tulos = KUST_SIMUL - &YlempiEritKorvKiintea;
	END;

	/* Annosjakelut lasketaan eri tavalla */
	ELSE IF OVAL_CUMU = 1 AND ANJA ne "" AND ika > &AlkuomavIkaraja1 THEN DO;
		IF RVMK_KERTY_SIMU - &AlkuomavTaso1 >= 2*&YlempiEritKorvKiinteaPoik THEN 
				&tulos = (RVMK_KERTY_SIMU - &AlkuomavTaso1) - 2*&YlempiEritKorvKiinteaPoik;
		ELSE IF RVMK_KERTY_SIMU - &AlkuomavTaso1 < 2*&YlempiEritKorvKiinteaPoik THEN 
					&tulos = 0;
	END;

	/* 18-vuotiaaksi saakka kaikki ovat korvattavia */
	ELSE IF (OVAL_CUMU > 1 OR ika <= &AlkuomavIkaraja1) AND ANJA NE "" THEN DO;
		IF rvmk_SIMU < 2*&YlempiEritKorvKiinteaPoik THEN 
				&tulos = 0;
		ELSE IF rvmk_SIMU >= 2*&YlempiEritKorvKiinteaPoik THEN 
					&tulos = rvmk_SIMU - 2*&YlempiEritKorvKiinteaPoik;
	END;
		

%MEND LaakKorvausEuro;

/* 3. Makro, joka laskee l‰‰kkeen reseptin omavastuun m‰‰r‰n kyseisen oston kohdalla */
/* Periaatteessa reseptin omavastuu on vastakohta korvaukselle */
*Makron parametrit:
	tulos: Makron tulosmuuttuja, reseptin omavastuun m‰‰r‰
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	klaji: L‰‰kelaji;

%MACRO LaakResOmaVastuuEuro(tulos, mvuosi, mkuuk, minf, klaji)/
DES = 'LAAKE: Korvauksen m‰‰r‰ (ilman kattokorvausta) l‰‰kkeen kohdalla, eurom‰‰r‰inen omavastuu';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);

	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
	/* Kokonaan alle alkuomavastuun olevissa l‰‰kkeiss‰ omavastuu = 0 (lis‰t‰‰n alkuomavastuu myˆhemmin) */
	IF OVAL_CUMU = 0 THEN &tulos = 0;
	/* Rajaoston kohdalla osa on korvattavaa ja osa alkuomavastuun piiriss‰ */
	IF OVAL_CUMU = 1 AND ANJA = "" and ika > &AlkuomavIkaraja1 THEN DO;
		IF RVMK_KERTY_SIMU - &AlkuomavTaso1 >= &YlempiEritKorvKiintea THEN DO;
				&tulos = &YlempiEritKorvKiintea;
			END;
			ELSE IF RVMK_KERTY_SIMU - &AlkuomavTaso1 < &YlempiEritKorvKiintea THEN DO;
					&tulos = RVMK_KERTY_SIMU - &AlkuomavTaso1;
				END;
		END;
	/* 18-vuotiaaksi saakka kaikki ovat korvattavia */
	IF (OVAL_CUMU > 1 OR ika <= &AlkuomavIkaraja1) AND ANJA = "" THEN DO;
		IF rvmk_SIMU < &YlempiEritKorvKiintea THEN DO;
				&tulos = rvmk_SIMU;
			END;
			ELSE IF rvmk_SIMU >= &YlempiEritKorvKiintea THEN DO;
					&tulos = &YlempiEritKorvKiintea;
				END;
		END;
	/* Annosjakelut lasketaan eri tavalla */
	IF OVAL_CUMU = 1 AND ANJA NE "" AND ika > &AlkuomavIkaraja1 THEN DO;
		IF RVMK_KERTY_SIMU - &AlkuomavTaso1 >= 2*&YlempiEritKorvKiinteaPoik THEN DO;
				&tulos = 2*&YlempiEritKorvKiinteaPoik;
			END;
			ELSE IF RVMK_KERTY_SIMU - &AlkuomavTaso1 < 2*&YlempiEritKorvKiinteaPoik THEN DO;
					&tulos = RVMK_KERTY_SIMU - &AlkuomavTaso1;
				END;
		END;

	/* 18-vuotiaaksi saakka kaikki ovat korvattavia */
	IF (OVAL_CUMU > 1 OR ika <= &AlkuomavIkaraja1) AND ANJA NE "" THEN DO;
		IF rvmk_simu < 2*&YlempiEritKorvKiinteaPoik THEN DO;
				&tulos = rvmk_SIMU;
			END;
			ELSE IF rvmk_SIMU >= 2*&YlempiEritKorvKiinteaPoik THEN DO;
					&tulos = 2*&YlempiEritKorvKiinteaPoik;
				END;
		END;
%MEND LaakResOmavastuuEuro;

/* 4. Makro, joka laskee l‰‰kkeen korvauksen m‰‰r‰n (ilman kattokorvausta) kyseisen oston kohdalla */

*Makron parametrit:
	tulos: Makron tulosmuuttuja, korvauksen m‰‰r‰
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	mkuuk: Kuukausi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	klaji: L‰‰kelaji;

%MACRO LaakKorvausPros(tulos, mvuosi, mkuuk, minf, klaji)/
DES = 'LAAKE: Korvauksen m‰‰r‰ (ilman kattokorvausta) l‰‰kkeen kohdalla, prosenttiperusteinen omavastuu';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);

	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
	/* Kokonaan alle alkuomavastuun olevissa l‰‰kkeiss‰ korvaus = 0 */
	IF OVAL_CUMU = 0 THEN &tulos = 0;
	/* Rajaoston kohdalla osa on korvattavaa ja osa alkuomavastuun piiriss‰ */
	IF (OVAL_CUMU = 1 AND ika > &AlkuomavIkaraja1) THEN DO;
		IF laji IN ("O","U") THEN DO;
				&tulos = ROUND(&PerusKorvPros*(RVMK_KERTY_SIMU - &AlkuomavTaso1), 0.01); 
			END;
		IF laji in ("Y") THEN DO;
				&tulos = ROUND(&AlempiEritKorvPros*(RVMK_KERTY_SIMU - &AlkuomavTaso1), 0.01); 
			END;
		END;
	/* 18-vuoteen saakka kaikki ovat korvattavia */
	IF (OVAL_CUMU > 1 OR ika <= &AlkuomavIkaraja1) THEN DO;
		IF laji in ("O","U") THEN DO;
				&tulos = ROUND(&PerusKorvPros*RVMK_SIMU, 0.01); 
			end;
		IF laji IN ("Y") THEN DO;
				&tulos = round(&AlempiEritKorvPros*RVMK_SIMU, 0.01); 
			END;
		END;
	
	
%MEND LaakKorvausPros;

/* 5. Makro, joka laskee l‰‰kkeen reseptin omavastuun m‰‰r‰n kyseisen oston kohdalla */
/* Periaatteessa reseptin omavastuu on vastakohta korvaukselle */
*Makron parametrit:
	tulos: Makron tulosmuuttuja, reseptin omavastuun m‰‰r‰
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	mkuuk: Kuukausi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	klaji: L‰‰kelaji;
%MACRO LaakResOmaVastuuPros(tulos, mvuosi, mkuuk, minf, klaji)/
DES = 'LAAKE: Korvauksen m‰‰r‰ (ilman kattokorvausta) l‰‰kkeen kohdalla, prosenttiperusteinen omavastuu';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);

	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
	/* Kokonaan alle alkuomavastuun olevissa l‰‰kkeiss‰ omavastuu = 0 (lis‰t‰‰n alkuomavastuu myˆhemmin) */
	IF OVAL_CUMU = 0 THEN &tulos = 0;
	/* Rajaoston kohdalla osa on korvattavaa ja osa alkuomavastuun piiriss‰ */
	IF OVAL_CUMU=1 AND ika > &AlkuomavIkaraja1 THEN DO;
			IF laji IN ("O","U") THEN DO;
				&tulos = ROUND((1-&PerusKorvPros)*(RVMK_KERTY_SIMU - &AlkuomavTaso1), 0.01); 
			end;
		IF laji IN ("Y") THEN DO;
				&tulos = ROUND((1-&AlempiEritKorvPros)*(RVMK_KERTY_SIMU - &AlkuomavTaso1), 0.01); 
			end;	
		end;

	/* Alle 18-vuotiailla kaikki ovat korvattavia. Tai on ollut aina t‰h‰n asti. */
	IF (OVAL_CUMU > 1 OR ika <= &AlkuomavIkaraja1) THEN DO;
		IF laji IN ("O","U") THEN DO;
				&tulos = ROUND((1-&PerusKorvPros)*RVMK_SIMU, 0.01); 
			END;
		IF laji IN ("Y") THEN DO;
				&tulos = ROUND((1-&AlempiEritKorvPros)*RVMK_SIMU, 0.01); 
			END;
		END;
	
%MEND LaakResOmaVastuuPros;
/* 6. Makro, joka laskee l‰‰kkeen kattokorvauksen m‰‰r‰n kyseisen oston kohdalla */
*Makron parametrin:
	tulos: Makron tulosmuuttuja, kattokorvauksen m‰‰r‰
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	mkuuk: Kuukausi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	;

%MACRO LaakKattoKorvausMaksettava(tulos, mvuosi, mkuuk, minf)/
DES = 'LAAKE: Kattokorvauksen m‰‰r‰ l‰‰kkeen kohdalla';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);

	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
	RETAIN YLI_KATTO_CUMU;
	/* Katsotaan, onko ylitt‰nyt katon */
	IF ROMAV_KERTY_SIMUL >= &LaakeKatto THEN YLI_KATTO=1;ELSE YLI_KATTO=0;
	
	IF FIRST.hnro THEN yli_katto_cumu=yli_katto;
		ELSE yli_katto_cumu=yli_katto_cumu + yli_katto;
	IF yli_katto_cumu=0 THEN &tulos=ROMAV_SIMUL;
	/* Ensimm‰inen katon ylitt‰nyt lasketaan hieman eri tavalla, koska se on osittain l‰‰kekaton alla */
	IF ANJA="" AND yli_katto_cumu=1 AND ROMAV_KERTY_SIMUL - &LaakeKatto >= &LaakekattoYlitKiintea THEN 
		&tulos = ROMAV_SIMUL - (ROMAV_KERTY_SIMUL - &LaakeKatto) + &LaakekattoYlitKiintea;
	IF ANJA="" AND yli_katto_cumu=1 AND ROMAV_KERTY_SIMUL - &LaakeKatto < &LaakekattoYlitKiintea THEN 
		&tulos = ROMAV_SIMUL;
	
	IF ANJA="" AND yli_katto_cumu > 1 AND ROMAV_SIMUL >= &LaakekattoYlitKiintea THEN 
		&tulos = &LaakekattoYlitKiintea;
	IF ANJA="" AND yli_katto_cumu > 1 AND ROMAV_SIMUL < &LaakekattoYlitKiintea THEN 
		&tulos = ROMAV_SIMUL;
	/* Annosjakeluissa on oma laskentakaavansa, koska omavastuu on viikoittainen */
	IF ANJA NE "" AND yli_katto_cumu=1 AND ROMAV_KERTY_SIMUL - &LaakeKatto >= 2*&LaakekattoYlitKiinteaPoikk THEN 
		&tulos = ROMAV_SIMUL - (ROMAV_KERTY_SIMUL - &LaakeKatto) + 2*&LaakekattoYlitKiinteaPoikk;
	IF ANJA NE "" AND yli_katto_cumu=1 AND ROMAV_KERTY_SIMUL - &LaakeKatto < 2*&LaakekattoYlitKiinteaPoikk THEN 
		&tulos = ROMAV_SIMUL;
	
	IF ANJA NE "" AND yli_katto_cumu > 1 AND ROMAV_SIMUL >= 2*&LaakekattoYlitKiinteaPoikk THEN 
		&tulos = 2*&LaakekattoYlitKiinteaPoikk;
	IF ANJA NE "" AND yli_katto_cumu > 1 AND ROMAV_SIMUL < 2*&LaakekattoYlitKiinteaPoikk THEN 
		&tulos = ROMAV_SIMUL;
	/* Jos on lis‰pakkaus ja ylitt‰‰ katon niin silloin ei lasketa omavastuuta. Omavastuu sis‰ltyy "emopakkauksen" riviin */
	IF JTJNO>0 AND yli_katto_cumu > 1 THEN
		&tulos = 0;
	

/*

*/
%MEND LaakKattoKorvausMaksettava;

/* 7. Makro, joka laskee l‰‰kkeen v‰hitt‰ismyyntihinnan */
/* Hahmottelu kesken!!! Ei v‰ltt‰m‰tt‰ viel‰ toimi luotettavasti */
*Makron parametrit:
	tulos: Makron tulosmuuttuja (luultavasti tekee monta tulosmuuttujaa nykyisell‰‰n)
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	;

%MACRO LaakTaksaVMH(tulos, mvuosi, mkuuk, minf)/
DES = 'LAAKE: L‰‰kkeen v‰hitt‰ismyyntihinta';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);

	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
	* Korjaan tukkuhinnat, laitan vanhan muuttujan p‰‰lle;
	IF RSTATUS^="1" THEN THINTA=&TukkuHintaAle*THINTA;
	* Ennen vuotta 2013 eri taksat, ne pit‰‰ ehk‰ myˆs laittaa t‰h‰n;
	* Ei tarvita en‰‰;
	*IF &mvuosi>2013 THEN;
		/* Reseptil‰‰kkeet */
		IF RSTATUS="1" THEN DO;
			 IF THINTA >= &TaksaEuroRes1 and THINTA <= &TaksaEuroRes2 THEN &tulos = &TaksaKerroinRes1 * THINTA + &TaksaKerroinRes2;
			 IF THINTA > &TaksaEuroRes2 and THINTA <= &TaksaEuroRes3 THEN &tulos = &TaksaKerroinRes3 * THINTA + &TaksaKerroinRes4;
			 IF THINTA > &TaksaEuroRes3 and THINTA <= &TaksaEuroRes4 THEN &tulos = &TaksaKerroinRes5 * THINTA + &TaksaKerroinRes6;
			 IF THINTA > &TaksaEuroRes4 and THINTA <= &TaksaEuroRes5 THEN &tulos = &TaksaKerroinRes7 * THINTA + &TaksaKerroinRes8;
			 IF THINTA > &TaksaEuroRes5 THEN &tulos = &TaksaKerroinRes9 * THINTA + &TaksaKerroinRes10;
		END;
		ELSE
		/* Muut l‰‰kkeet */
		IF	RSTATUS ^= "1" THEN DO;
			IF THINTA >= &TaksaEuroEiRes1 AND THINTA <= &TaksaEuroEiRes2 THEN &tulos = &TaksaKerroinEiRes1 * THINTA + &TaksaKerroinEiRes2;
			IF THINTA > &TaksaEuroEiRes2 AND THINTA <= &TaksaEuroEiRes3 THEN &tulos = &TaksaKerroinEiRes3 * THINTA + &TaksaKerroinEiRes4;
			IF THINTA > &TaksaEuroEiRes3 AND THINTA <= &TaksaEuroEiRes4 THEN &tulos = &TaksaKerroinEiRes5 * THINTA + &TaksaKerroinEiRes6;
			IF THINTA > &TaksaEuroEiRes4 AND THINTA <= &TaksaEuroEiRes5 THEN &tulos = &TaksaKerroinEiRes7 * THINTA + &TaksaKerroinEiRes8;
			IF THINTA > &TaksaEuroEiRes5 THEN &tulos = &TaksaKerroinEiRes9 * THINTA + &TaksaKerroinEiRes10;
		END;
	*Vero lis‰‰;
	&tulos=round(&tulos + &LaakeAlv*&tulos, 0.01);
%MEND LaakTaksaVMH;


/* 8. Makro, joka laskee l‰‰kkeen viitehinnan */
/* Hahmottelu kesken!!! */
/* Luultavasti viitehinnan laskenta tehd‰‰n keskell‰ makroa LaakTaksa */
/* Viitehinta pit‰‰ laskea uudestaan, jos tehd‰‰n muutoksia taksataulukoihin tai tukkuhintoihin */
/* Viitehinta on vuosikvartaalin ensimm‰isen 2 viikon jakson halvin hinta + 0,5e substituutioryhm‰ss‰ */
*Makron parametrit:
	tulos: Makron tulosmuuttuja, alkuomavastuun m‰‰r‰
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n

	;

%MACRO LaakViiteHinta(tulos, mvuosi, mkuuk, minf)/
DES = 'LAAKE: L‰‰kkeen myyntihinta';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);

	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
	if first.SUBKOODI
		then do;
			if VMH_SIMU<&LaakeTaksaPutkiRaja then &tulos=VMH_SIMU + &LaakeTaksaPutki1; 
			if VMH_SIMU>=&LaakeTaksaPutkiRaja then  &tulos=VMH_SIMU + &LaakeTaksaPutki2; 
			output;
			end;

%MEND LaakViiteHinta;

/* 9. Makro, joka laskee l‰‰kkeen lopullisen myyntihinnan */
/* Hahmottelu kesken!!! Ei v‰ltt‰m‰tt‰ viel‰ toimi luotettavasti */
*Makron parametrit:
	tulos: Makron tulosmuuttuja (luultavasti tekee monta tulosmuuttujaa nykyisell‰‰n)
	mvuosi: Vuosi, jonka lains‰‰d‰ntˆ‰ k‰ytet‰‰n
	;

%MACRO LaakTaksa(tulos, mvuosi, mkuuk, minf)/
DES = 'LAAKE: L‰‰kkeen myyntihinta';
	%HaeParam&TYYPPI(&mvuosi, &mkuuk, &LAAKE_PARAM, PARAM.&PLAAKE);
	%ParamInf&TYYPPI(&mvuosi, &mkuuk, &LAAKE_MUUNNOS, &minf);

	%LuoKuuID(kuuid, &mvuosi, &mkuuk);
	/* Jos lasketaan viitehinta, pit‰‰ viitehintamakron tulla t‰h‰n */
	 *Lasketaan kokonaiskustannus pakkauksen hinnan perusteella toimitusmaksuineen;
	/* Laitan t‰h‰n varmuuden vuoksi alkuper‰isen kustannuksen */
	/* Mik‰li mit‰‰n hintaa ei lˆydy, pidet‰‰n vanha hinta */
	KUST_SIMUL=KUST;
	RVMK_SIMU=RVMK;
	IF VMH_SIMU>=0 THEN KUST_SIMUL = PLKM*VMH_SIMU + &LaakeToimMaksu + &LaakeAlv * &LaakeToimMaksu;

	IF VIHINTA_SIMU>0 THEN 
			RVMK_SIMU=PLKM*VIHINTA_SIMU + &LaakeToimMaksu + &LaakeAlv*&LaakeToimMaksu;
		ELSE RVMK_SIMU=KUST_SIMUL;
	*annosjakeluja varten pit‰‰ tehd‰ ylim‰‰r‰inen muuttuja, jonka laskemisessa k‰ytet‰‰n alkuper‰ist‰ kustannusta;
	*k‰ytet‰‰n toistaiseksi olettamuksena 2 viikon toimitusta, koska toimitusv‰liin ei ole luotettavaa muuttujaa;
	IF ANJA^="" THEN PRO_ANJA = KUST / (PLKM*VHINTA + round((&LaakeToimMaksu + &LaakeAlv*&LaakeToimMaksu)/6, 0.01));
	IF VIHINTA_SIMU>0 AND ANJA^="" AND PRO_ANJA^=. THEN RVMK_SIMU = PRO_ANJA * VIHINTA_SIMU + round((&LaakeToimMaksu + &LaakeAlv*&LaakeToimMaksu)/6, 0.01);
	IF (VIHINTA_SIMU=0 OR VIHINTA_SIMU=.) AND ANJA^="" AND PRO_ANJA^=. THEN RVMK_SIMU = PRO_ANJA * VMH_SIMU + round((&LaakeToimMaksu + &LaakeAlv*&LaakeToimMaksu)/6, 0.01);
	IF VMH_SIMU^=. AND ANJA^="" AND PRO_ANJA^=. THEN KUST_SIMUL = PRO_ANJA * VMH_SIMU + round((&LaakeToimMaksu + &LaakeAlv*&LaakeToimMaksu)/6, 0.01);
    
	IF VMH_SIMU^=. AND ANJA^="" AND PRO_ANJA^=. AND KUST_SIMUL > RVMK_SIMU  THEN RVMK_SIMU = KUST_SIMUL;
	/* Lis‰pakkaus, ei toimituskuluja */
	IF VMH_SIMU^=. AND JTJNO>0 THEN KUST_SIMUL = PLKM * VMH_SIMU;
	IF VIHINTA_SIMU>0 AND JTJNO>0 THEN RVMK_SIMU = PLKM*VIHINTA_SIMU;
	IF (VIHINTA_SIMU=0 OR VIHINTA_SIMU=.) AND JTJNO>0 AND VMH_SIMU^=. THEN RVMK_SIMU = PLKM * VMH_SIMU;
	*L‰‰k‰rin kielto vaihdolle, ei lis‰omavastuuta joten RVMK=KUST;
	IF RGENK in ('L', 'P', 'E', 'S', 'V') THEN RVMK_SIMU = KUST_SIMUL;
	*RVMK ei voi olla suurempi kuin KUST;
	IF RVMK_SIMU > KUST_SIMUL THEN RVMK_SIMU = KUST_SIMUL;
	RVMK_SIMU=round(RVMK_SIMU, 0.01);
	KUST_SIMUL=round(KUST_SIMUL, 0.01);
	* Jos kyseess‰ on l‰‰keseos, ei hintaa muuteta. T‰t‰ pit‰‰ ehk‰ muuttaa jatkossa...; 
	IF RTUN="L" THEN DO;
			KUST_SIMUL=KUST;
			RVMK_SIMU=RVMK;
		END;
	

%MEND LaakTaksa;

