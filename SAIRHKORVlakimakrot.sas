
* Yksityisen terveydenhuollon korvaukset
tulos = korvaus, Ä/rivi
taksa = toimenpiteen taksa, Ä (asetuksesta)
akoro = aikakorotus (0/1)
ekoro = erikoisl‰‰k‰rikorotus (0/1)
kkoro = kotik‰yntikorotus (0/1)
laji	1 = L‰‰k‰rinpalkkio
		2 = Hammasl‰‰k‰rinpalkkio
		3 = Tutkimus ja hoito
kerrat = k‰yntikerrat / rivi
maksukerta = samaan maksukertaan kuuluvan maksun tunniste;

%MACRO YksTervKorv(tulos,mvuosi,mkuuk,minf,taksa,kust,akoro,ekoro,kkoro,laji,kerrat,maksukerta);
%HaeParam&TYYPPI(&mvuosi, &mkuuk, &SAIRHKORV_PARAM, PARAM.&PSAIRHKORV);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &SAIRHKORV_MUUNNOS, &minf);


temp = MIN(&kust, &taksa * &kerrat * &minf);

IF &kkoro THEN temp = temp * (1+&KotiKor);
IF &laji NE 3 THEN DO;
	IF &akoro THEN temp = temp * (1+&AikaKor);
	IF &ekoro THEN DO;
		IF &laji = 2 THEN temp= temp * (1+&HErikLaakKor);
		ELSE temp = temp * (1+&ErikLaakKor);
	END;
END;

IF &mvuosi < 2013 THEN DO;
	IF FLOOR(&laji) IN (1,2) THEN temp = &TaksaProsLaak * temp;
	ELSE DO;
		BY &maksukerta;
		IF first.&maksukerta THEN kertyma = 0;
		kertyma + temp;
		IF last.&maksukerta THEN temp = MAX(0, SUM(&TaksaProsTutkH * kertyma, -&TutkHoitoOmaV));
		ELSE temp = 0;
	END;
END;


&tulos = ROUND(temp,0.01);

drop temp kertyma;
%MEND;


* Matkakorvaukset, ilman kattoa, tietyn kuukauden lains‰‰d‰ntˆ

tulos = korvaus, Ä/rivi
omavkerrat = kuinka monta omavastuuta sis‰ltyy riviin
matlkm = kuinka monta matkaa sis‰ltyy riviin
kust = matkakustannukset
kilom = omalla autolla kuljetun matkan kilometrit
kulkuneu = mik‰ kulkuneuvo kyseess‰
taksikoro = onko kyseess‰ korotetun omavastuun taksimatka (0/1)
yopraha = onko kyseess‰ yˆpymisraha (0/1)
;


%MACRO MatkaKorvSIMULX(tulos,mvuosi,mkuuk,minf,omavkerrat,matlkm,kust,kilom,kulkuneu,taksikoro,yopraha);
%HaeParam&TYYPPI(&mvuosi, &mkuuk, &SAIRHKORV_PARAM, PARAM.&PSAIRHKORV);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &SAIRHKORV_MUUNNOS, &minf);

IF NOT &kilom THEN DO;
	IF &taksikoro = 1 THEN &tulos = MAX(0, SUM(&kust, - &omavkerrat * &TaksiOmavKor));
	ELSE IF &yopraha = 1 THEN &tulos = &omavkerrat * &YopymisRaha;
	ELSE IF &kulkuneu=1 THEN &tulos = MAX(0, SUM(&kust, - &omavkerrat * &MatkaOmavPerus));
	ELSE IF &kulkuneu=2 THEN &tulos = MAX(0, SUM(&kust, - &omavkerrat * &MatkaOmavPerus));
	ELSE &tulos = MAX(0, SUM(&kust, - &omavkerrat * &MatkaOmavPerus));

END;
ELSE &tulos =  MAX(0, SUM(&omavkerrat/&matlkm * &kilom * &KiloMetriKorv, - &omavkerrat * &MatkaOmavPerus)); 

&tulos=ROUND(&tulos,0.01);
%MEND;

* Matkakorvaukset, eri kuukausina eri lains‰‰d‰ntˆ

tulos = korvaus, Ä/rivi
omavkerrat = kuinka monta omavastuuta sis‰ltyy riviin
matlkm = kuinka monta matkaa sis‰ltyy riviin
kust = matkakustannukset
kilom = omalla autolla kuljetun matkan kilometrit
kulkuneu = mik‰ kulkuneuvo kyseess‰
taksikoro = onko kyseess‰ korotetun omavastuun taksimatka (0/1)
yopraha = onko kyseess‰ yˆpymisraha (0/1)
;



%MACRO MatkaKorvSIMUL(tulos,mvuosi,kuuk,minf,omavkerrat,matlkm,kust,kilom,kulkuneu,taksikoro,yopraha);


%DO i = 1 %TO 12;
	IF &i = &kuuk THEN DO;
		%MatkaKorv(&tulos,&mvuosi,&i,&minf,&omavkerrat,&matlkm,&kust,&kilom,&kulkuneu,&taksikoro,&yopraha);
	END;
%END;


%MEND;

*Matkakustannusten p‰ivitt‰minen hintaindeksill‰;

%MACRO MatkaKustSIMUL(tulos,mvuosi,mkuuk,minf,kust,kulkuneu);
%HaeParam&TYYPPI(&mvuosi, &mkuuk, &SAIRHKORV_PARAM, PARAM.&PSAIRHKORV);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &SAIRHKORV_MUUNNOS, &minf);

%IF &HINTAIND=0 %THEN %DO;
&tulos= &kust;
%END;
%ELSE %DO;

IF &kulkuneu=1 THEN &tulos= &kust * &TaksiInd * &minf;
ELSE IF &kulkuneu=2 THEN &tulos=&kust * &AmbuInd * &minf;
ELSE IF &kulkuneu=3 THEN &tulos=&kust * &OmaAutoInd * &minf;
ELSE  &tulos=&kust;
%END;

&tulos=ROUND(MAX(0,&tulos),0.01);

%MEND;

* Matkakorvausten maksukaton laskenta

tulos = korvaus, Ä/rivi
omavastuu = matkan omavastuu ilman katon vaikutusta
korvaus = matkan korvaus ilman katon vaikutusta
taksikoro = onko kyseess‰ korotetun omavastuun taksimatka (0/1)
yopymisraha = onko kyseess‰ yˆpymisraha (0/1)
;



%MACRO MatkaKatto(tulos,mvuosi,minf,korvaus,omavastuu,taksikoro,yopymisraha);
%HaeParam&TYYPPI(&mvuosi, 1, &SAIRHKORV_PARAM, PARAM.&PSAIRHKORV);
%ParamInf&TYYPPI(&mvuosi, 1, &SAIRHKORV_MUUNNOS, &minf);

BY hnro;
IF first.hnro THEN omavkertyma=0;
IF &yopymisraha NE 1 AND (&taksikoro NE 1 OR &mvuosi < 2015) THEN DO;	

	omavkertyma + &omavastuu;

	IF omavkertyma > &MatkaKatto THEN DO;

		IF omavkertyma - &omavastuu < &MatkaKatto THEN temp = &korvaus + (omavkertyma - &MatkaKatto);
		ELSE temp = &korvaus + &omavastuu;

	END;

	ELSE temp = &korvaus;

END;
ELSE temp = &korvaus;

&tulos=ROUND(MAX(0,temp),0.01);

drop temp;
%MEND;


