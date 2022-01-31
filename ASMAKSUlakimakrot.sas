
*Avohoidon maksujen simulointimakro, lainsäädännön enimmäismäärät

ika=potilaan ikä
laji= käynnin tyyppi
kerta= käynnin järjestysnumero vuoden aikana
psyk = käynti psykiatrilla
pyhayo = käynti pyhäpäivänä, yöaikaan (klo 20-8) tai viikonloppuna (0/1)
laakari = onko hammaslääkärin käynti (0/1)
vuosimaksu = lasketaanko vuosimaksu (1) vai kertamaksu (0)
hoitaja = simuloitavan hoitajamaksun suuruus (€/käynti);


%MACRO AvoHoito(tulos,mvuosi,mkuuk,minf,ika,laji,kerta,psyk,pyhayo,laakari=1,vuosimaksu=0,hoitaja=0)/ 
DES = ' ';
%HaeParam&TYYPPI(&mvuosi, 1, &ASMAKSU_PARAM, PARAM.&PASMAKSU);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &ASMAKSU_MUUNNOS, &minf);


IF &laji= 7 THEN temp= &PaivaKirurgia;

ELSE IF &laji = 8 AND NOT &psyk THEN temp= &LaitosPaivaYo;

ELSE IF FLOOR(&laji) = 9 THEN DO;
	IF &psyk NE 1 THEN temp = &PoliKlinKerta;
	ELSE temp=0;
END;

ELSE IF &laji = 10 AND &ika >= &IkaRaja THEN DO;
	IF &pyhayo THEN temp = &AvoKertaMaksuYo;
	ELSE DO;
		IF &vuosimaksu=1 AND &kerta = 1 THEN temp = &AvoVuosiMaksu;
		ELSE IF &vuosimaksu =0 AND &kerta<=3 THEN temp = &AvoKertaMaksu; 
		ELSE temp=0;
	END;
END;

ELSE IF &laji = 12 THEN DO;
		IF NOT &psyk AND &ika >= &IkaRaja AND &kerta <= &SarjaKerratMax THEN temp= &SarjaHoitoKerta;
		ELSE temp = 0;
END;

ELSE IF &laji = 11 THEN temp = &FysioKerta;

ELSE IF 12< &laji < 27 AND &ika >= &IkaRaja THEN DO;

	IF &laji = 13 THEN temp = &KuvantamisHammas;
	ELSE IF &laji = 14 THEN temp = &KuvaPanoraama;
	ELSE IF &laji = 15 THEN temp = &EhkaisevaSC;
	ELSE IF &laji = 16 THEN temp = &ProteesiPohj;
	ELSE IF &laji = 17 THEN temp = &ProteesiKorj;
	ELSE IF &laji = 18 THEN temp = &AkryyliProteesi;
	ELSE IF &laji = 19 THEN temp = &KruunuSilta;
	ELSE IF &laji = 20 THEN temp = &RankaProteesi;
	ELSE IF &laji = 21 THEN temp = &ToimenP_v0_2;
	ELSE IF &laji = 22 THEN temp = &ToimenP_v3_4;
	ELSE IF &laji = 23 THEN temp = &ToimenP_v5_7;
	ELSE IF &laji = 24 THEN temp = &ToimenP_v8_10;
	ELSE IF &laji = 25 THEN temp = &ToimenP_v11_;

	IF &kerta=1 OR &laji=26 THEN DO;
		IF &laakari THEN temp = SUM(temp, &HammasLaakariKerta);
		ELSE temp = SUM(temp, &SuuHygienistiKerta);
	END; 

END;

ELSE IF &laji = 27 AND &ika >= &IkaRaja THEN temp = &hoitaja;

ELSE temp=0;


&tulos=temp;

%MEND AvoHoito;

*Asiakasmaksujen maksukaton simulointimakro

laji= käynnin tyyppi
ika=potilaan ikä
maksu=maksun suuruus ilman katon vaikutusta
kertyma= käyntiä edeltävä maksukertymä vuoden aikana
hoitopv = lyhytaikaisen laitoshoidon hoitojakson pituus (pv) 
;

%MACRO MaksuKatto(tulos,mvuosi,mkuuk,minf,laji,ika,maksu,kertyma,hoitopv)/ 
DES = 'Maksukaton soveltaminen';

%HaeParam&TYYPPI(&mvuosi, 1, &ASMAKSU_PARAM, PARAM.&PASMAKSU);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &ASMAKSU_MUUNNOS, &minf);


IF &kertyma > &MaksuKatto THEN DO;


*Jos maksukatto ylittyy juuri kyseisen maksun toimesta, maksu jaetaan maksukaton alittavaan ja ylittävään osaan;
	IF &maksu > &kertyma - &MaksuKatto THEN DO;

		IF &laji = 5 AND &ika >= &IkaRaja THEN temp = (&Maksukatto- (&kertyma-&maksu)) + ((&kertyma - &MaksuKatto) / &maksu) * &hoitopv * &LyhytAikKatonJalk;
		ELSE temp = &MaksuKatto - (&kertyma - &maksu);

	END;
	ELSE IF &laji=5 AND &ika >= &IkaRaja THEN temp= &hoitopv * &LyhytAikKatonJalk;
	ELSE temp=0;

END;
ELSE temp=&maksu;

IF .<temp<0 THEN &tulos=0;
ELSE &tulos=ROUND(temp,0.01);

%MEND MaksuKatto;

*Kotihoidon maksujen simulointimakro, enimmäismäärät

kuukkerrat = käyntikerrat kuukaudessa
jasenia = jäsenten lkm kotitaloudessa
jasennro = jäsenen järjestysnumero kotitaloudessa
bruttotulo = kotitalouden bruttotulo (€/kk)
laakari = onko kyseessä lääkärin käynti (0/1)
saannol= onko tehty pitkäaikaishoidon suunnitelma (0/1)
maxkustannus = maksimikustannus per käynti (€), yleensä tuotantokustannukset
;


%MACRO KotiHoito(tulos,mvuosi,mkuuk,minf,kuukkerrat,jasenia,jasennro,bruttotulo,laakari,saannol=1,maxkustannus=38)/ 
DES = 'Kotihoidon maksut';
%HaeParam&TYYPPI(&mvuosi, 1, &ASMAKSU_PARAM, PARAM.&PASMAKSU);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &ASMAKSU_MUUNNOS, &minf);

IF &jasennro=1 THEN DO;
IF &kuukkerrat >= 54 THEN DO;

      IF &jasenia = 1 THEN temp = &KHMaksuPros1 * SUM(&bruttotulo,-&KHSuojaOsa1);
      ELSE IF &jasenia = 2 THEN temp = &KHMaksuPros2 * SUM(&bruttotulo,-&KHSuojaOsa2);
	  ELSE IF &jasenia = 3 THEN temp = &KHMaksuPros3 * SUM(&bruttotulo,-&KHSuojaOsa3);
	  ELSE IF &jasenia = 4 THEN temp = &KHMaksuPros4 * SUM(&bruttotulo,-&KHSuojaOsa4);
	  ELSE IF &jasenia = 5 THEN temp = &KHMaksuPros5 * SUM(&bruttotulo,-&KHSuojaOsa5);
	  ELSE IF &jasenia = 6 THEN temp = &KHMaksuPros6 * SUM(&bruttotulo,-&KHSuojaOsa6);
      ELSE IF &jasenia > 6 THEN temp = SUM(&KHMaksuPros6, -(&jasenia - 6) *&KHMaksuProsLisa)* SUM(&bruttotulo,- SUM(&KHSuojaOsa6, (&jasenia -6) * &KHSuojaOsaLisa));

END;
ELSE IF &kuukkerrat >= 18 THEN DO;

      IF &jasenia = 1 THEN temp = 0.3 * SUM(&bruttotulo,-&KHSuojaOsa1);
      ELSE IF &jasenia > 1 THEN temp = 0.2 * SUM(&bruttotulo,-&KHSuojaOsa2);

END;
ELSE IF (&kuukkerrat >=6 AND &saannol=1) OR &kuukkerrat >= 18 THEN DO;

	
     IF &jasenia = 1 THEN temp = 0.22 * SUM(&bruttotulo,-&KHSuojaOsa1);
     ELSE IF &jasenia > 1 THEN temp = 0.18 * SUM(&bruttotulo,-&KHSuojaOsa2);

END;
ELSE temp = &kuukkerrat * SUM(&laakari * &KHKertaMaksu1, (1-&laakari) * &KHKertaMaksu2);
END;
ELSE temp=0;



IF .<temp<0 THEN &tulos=0;
ELSE &tulos=ROUND(MIN(&maxkustannus*&kuukkerrat, temp),0.01);

drop temp;
%MEND KotiHoito;

*Kotihoidon maksujen simulointimakro, kuntatasot

kuukkerrat = käyntikerrat kuukaudessa
jasenia = jäsenten lkm kotitaloudessa
jasennro = jäsenen järjestysnumero kotitaloudessa
bruttotulo = kotitalouden bruttotulo (€/kk)
laakari = onko kyseessä lääkärin käynti (0/1)
saannol= onko tehty pitkäaikaishoidon suunnitelma (0/1)
maxkustannus = maksimikustannus per käynti (€), yleensä tuotantokustannukset
;


%MACRO KotiHoitoKunta(tulos,mvuosi,mkuuk,minf,kuukkerrat,jasenia,jasennro,bruttotulo,laakari,saannol=1,maxkustannus=38)/ 
DES = 'Kotihoidon maksut';
%HaeParam&TYYPPI(&mvuosi, 1, &ASMAKSU_PARAM, PARAM.&PASMAKSU);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &ASMAKSU_MUUNNOS, &minf);

IF &jasennro=1 THEN DO;
IF &kuukkerrat >= 120 THEN DO;

      IF &jasenia = 1 THEN temp = &KHMaksuPros1 * SUM(&bruttotulo,-&KHSuojaOsa1);
      ELSE IF &jasenia = 2 THEN temp = &KHMaksuPros2 * SUM(&bruttotulo,-&KHSuojaOsa2);
	  ELSE IF &jasenia = 3 THEN temp = &KHMaksuPros3 * SUM(&bruttotulo,-&KHSuojaOsa3);
	  ELSE IF &jasenia = 4 THEN temp = &KHMaksuPros4 * SUM(&bruttotulo,-&KHSuojaOsa4);
	  ELSE IF &jasenia = 5 THEN temp = &KHMaksuPros5 * SUM(&bruttotulo,-&KHSuojaOsa5);
	  ELSE IF &jasenia = 6 THEN temp = &KHMaksuPros6 * SUM(&bruttotulo,-&KHSuojaOsa6);
      ELSE IF &jasenia > 6 THEN temp = SUM(&KHMaksuPros6, -(&jasenia - 6) *&KHMaksuProsLisa)* SUM(&bruttotulo,- SUM(&KHSuojaOsa6, (&jasenia -6) * &KHSuojaOsaLisa));

END;

ELSE IF &kuukkerrat >= 54 THEN DO;

    IF &jasenia = 1 THEN DO;
			temp = 0.3 * SUM(&bruttotulo,-&KHSuojaOsa1);
	END;
    ELSE IF &jasenia = 2 THEN DO;
			temp = 0.24 * SUM(&bruttotulo,-&KHSuojaOsa2);
	END;
	ELSE IF &jasenia = 3 THEN temp = &KHMaksuPros3 * SUM(&bruttotulo,-&KHSuojaOsa3);
	ELSE IF &jasenia = 4 THEN temp = &KHMaksuPros4 * SUM(&bruttotulo,-&KHSuojaOsa4);
	ELSE IF &jasenia = 5 THEN temp = &KHMaksuPros5 * SUM(&bruttotulo,-&KHSuojaOsa5);
	ELSE IF &jasenia = 6 THEN temp = &KHMaksuPros6 * SUM(&bruttotulo,-&KHSuojaOsa6);
    ELSE IF &jasenia > 6 THEN temp = SUM(&KHMaksuPros6, -(&jasenia - 6) *&KHMaksuProsLisa)* SUM(&bruttotulo,- SUM(&KHSuojaOsa6, (&jasenia -6) * &KHSuojaOsaLisa));

END;
ELSE IF &kuukkerrat >= 18 THEN DO;

      IF &jasenia = 1 THEN temp = 0.16 * SUM(&bruttotulo,-&KHSuojaOsa1);
      ELSE IF &jasenia > 1 THEN temp = 0.14 * SUM(&bruttotulo,-&KHSuojaOsa2);

END;
ELSE IF &kuukkerrat >= 6 AND &saannol=1 THEN DO;

      IF &jasenia = 1 THEN temp = 0.08 * SUM(&bruttotulo,-&KHSuojaOsa1);
      ELSE IF &jasenia > 1 THEN temp = 0.07 * SUM(&bruttotulo,-&KHSuojaOsa2);

END;
ELSE temp = &kuukkerrat * SUM(&laakari * &KHKertaMaksu1, (1-&laakari) * MIN(KHKertaMaksu2, &KHKertaMaksu2));
END;
ELSE temp=0;



IF .<temp<0 THEN &tulos=0;
ELSE &tulos=ROUND(MIN(&maxkustannus*&kuukkerrat, temp),0.01);

drop temp;
%MEND;


*Avohoidon maksujen simulointimakro, kuntatasot

ika=potilaan ikä
laji= käynnin tyyppi
kerta= käynnin järjestysnumero vuoden aikana
psyk = käynti psykiatrilla
pyhayo = käynti pyhäpäivänä, yöaikaan (klo 20-8) tai viikonloppuna (0/1)
laakari = onko hammaslääkärin käynti (0/1)
vuosimaksu = lasketaanko vuosimaksu (1) vai kertamaksu (0)
hoitaja = simuloitavan hoitajamaksun suuruus (€/käynti);


%MACRO AvoHoitoKunta(tulos,mvuosi,mkuuk,minf,ika,laji,kerta,psyk,pyhayo,laakari=1,vuosimaksu=0,hoitaja=0)/ 
DES = ' ';
%HaeParam&TYYPPI(&mvuosi, 1, &ASMAKSU_PARAM, PARAM.&PASMAKSU);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &ASMAKSU_MUUNNOS, &minf);

IF &laji= 7 THEN temp= MIN(PaivaKirurgia,&PaivaKirurgia);

ELSE IF &laji = 8 AND NOT &psyk THEN temp= MIN(&LaitosPaivaYo,LyhytaikKatonJalk*&minf);

ELSE IF FLOOR(&laji) = 9 and &ika>=&ikaraja THEN DO;
	IF &psyk=1 THEN temp=0;
	ELSE IF &laji=9.5 THEN temp = MIN(PoliHoitaja*&minf,&PoliKlinKerta);
	ELSE temp = MIN(PoliKlinKerta*&minf,&PoliKlinKerta);
END;


ELSE IF &laji = 10 AND &ika >= &IkaRaja THEN DO;
	IF &pyhayo THEN temp = &AvoKertaMaksuYo;
	ELSE DO;
		IF TK_MAKKERRAT=1 AND &kerta = 1 AND &psyk=. THEN temp = MIN(AvoVuosiMaksu*&minf,&AvoVuosiMaksu);
		ELSE IF (&kerta <= TK_MAKKERRAT) OR (&psyk=0 AND &kerta <=3) THEN temp = MIN(&AvoKertaMaksu,AvoKertaMaksu*&minf); 
		ELSE temp=0;
	END;
END;

ELSE IF &laji = 11 AND &kerta <= &SarjaKerratMax THEN temp = MIN(FysioKerta*&minf,&FysioKerta);

ELSE IF &laji = 12 THEN DO;
		IF NOT &psyk AND &ika >= &IkaRaja AND &kerta <= &SarjaKerratMax THEN temp= MIN(SarjaHoitoKerta*&minf,&SarjaHoitoKerta);
		ELSE temp = 0;
END;

ELSE IF 12< &laji < 27 AND &ika >= &IkaRaja THEN DO;

	IF &laji = 13 THEN temp = MIN(&KuvantamisHammas,KuvantamisHammas*&minf);
	ELSE IF &laji = 14 THEN temp = MIN(&KuvaPanoraama,KuvaPanoraama*&minf);
	ELSE IF &laji = 15 THEN temp = MIN(&EhkaisevaSC,EhkaisevaSC*&minf);
	ELSE IF &laji = 16 THEN temp = MIN(&ProteesiPohj,ProteesiPohj*&minf);
	ELSE IF &laji = 17 THEN temp = MIN(&ProteesiKorj,ProteesiKorj*&minf);
	ELSE IF &laji = 18 THEN temp = MIN(&AkryyliProteesi,AkryyliProteesi*&minf);
	ELSE IF &laji = 19 THEN temp = MIN(&KruunuSilta,KruunuSilta*&minf);
	ELSE IF &laji = 20 THEN temp = MIN(&RankaProteesi,RankaProteesi*&minf);
	ELSE IF &laji = 21 THEN temp = MIN(&ToimenP_v0_2,ToimenP_v0_2*&minf);
	ELSE IF &laji = 22 THEN temp = MIN(&ToimenP_v3_4,ToimenP_v3_4*&minf);
	ELSE IF &laji = 23 THEN temp = MIN(&ToimenP_v5_7,ToimenP_v5_7*&minf);
	ELSE IF &laji = 24 THEN temp = MIN(&ToimenP_v8_10,ToimenP_v8_10*&minf);
	ELSE IF &laji = 25 THEN temp = MIN(&ToimenP_v11_,ToimenP_v11_*&minf);

	IF &kerta=1 OR &laji=26 THEN DO;
		IF &laakari THEN temp = SUM(temp, MIN(&HammasLaakariKerta,HammasLaakariKerta*&minf));
		ELSE temp = SUM(temp, MIN(&SuuHygienistiKerta,SuuHygienistiKerta*&minf));
	END; 

END;

ELSE IF &laji = 27 THEN DO;
	IF  &ika >= &IkaRaja AND ((hoitaja_tk > 20.9 AND &kerta = 1) or (hoitaja_tk <= 20.9 AND &kerta<=3)) THEN temp = hoitaja_tk*&minf;
	ELSE temp=0; 
END;


&tulos=temp;

%MEND;

*Laitoshoidon ja tehostetun palveluasumisen maksujen simulointimakro, kuntatasot

ika=potilaan ikä
laji= hoidon tyyppi
tulot = asiakkaan nettotulot (€/kk)
puoltulot = puolison nettotulot (€/kk)
psyk = psykiatrinen hoito (0/1)
maxkustannus = maksimikustannus per kk (€), yleensä tuotantokustannukset;


%MACRO LaitosHoitoKunta(tulos,mvuosi,mkuuk,minf,ika,laji,tulot,puoltulot,psyk=0,maxkustannus=6000)/ 
DES = 'Laitoshoidon maksut';
%HaeParam&TYYPPI(&mvuosi, 1, &ASMAKSU_PARAM, PARAM.&PASMAKSU);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &ASMAKSU_MUUNNOS, &minf);


*Pitkäaikaisen laitoshoidon maksu /NETTOTULO;
IF &laji=1  THEN DO;

	IF NOT &puoltulot OR &tulot < &puoltulot THEN temp= &PitkaLaitosPros1 * &tulot;
	ELSE temp= &PitkaLaitosPros2 * SUM(&tulot, &puoltulot);

	IF SUM(&tulot,-temp) < &PitkaLaitosSuojaOsa THEN temp=SUM(&tulot,-&PitkaLaitosSuojaOsa);
	
	IF &ika < &IkaRaja THEN temp=0;
END;

*Tehostettu eli ympärivuorokautinen palveluasuminen /NETTOTULO;
ELSE IF &laji=2 THEN DO;
	IF NOT &puoltulot OR &tulot < &puoltulot THEN temp= &PitkaLaitosPros1 * &tulot;
	ELSE temp= &PitkaLaitosPros2 * SUM(&tulot, &puoltulot);

	IF SUM(&tulot,-temp) < &PitkaLaitosSuojaOsa THEN temp=SUM(&tulot,-&PitkaLaitosSuojaOsa);
END;


ELSE IF &laji=5 THEN DO;
	IF &psyk=1 THEN temp=MIN(LyhytaikKatonJalk*&minf,&LyhytAikLaitosPsyk);
	ELSE IF &psyk=0 THEN temp=MIN(&LyhytAikLaitosMuu,LyhytAikLaitosMuu*&minf);
	ELSE IF &psyk=. THEN temp=MIN(&LyhytAikLaitosMuu,LyhytAikLaitosPTH*&minf);
END;

ELSE IF &laji=6 THEN temp= &KuntHoitMaksu;


IF .<temp<0 THEN &tulos=0;
ELSE &tulos=ROUND(MIN(&maxkustannus, temp),0.01);
drop temp;

%MEND;

*Asiakasmaksujen maksukaton simulointimakro, kuntatasot

laji= käynnin tyyppi
ika=potilaan ikä
maksu=maksun suuruus ilman katon vaikutusta
kertyma= käyntiä edeltävä maksukertymä vuoden aikana
hoitopv = lyhytaikaisen laitoshoidon hoitojakson pituus (pv) 
erikoissh = onko kyseessä erikoissairaanhoidon laitoshoito (0/1)
;

%MACRO MaksuKattoKunta(tulos,mvuosi,mkuuk,minf,laji,ika,maksu,kertyma,hoitopv,erikoissh=1)/ 
DES = 'Maksukaton soveltaminen';

%HaeParam&TYYPPI(&mvuosi, 1, &ASMAKSU_PARAM, PARAM.&PASMAKSU);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &ASMAKSU_MUUNNOS, &minf);


IF &kertyma > &MaksuKatto THEN DO;


*Jos maksukatto ylittyy juuri kyseisen maksun toimesta, maksu jaetaan maksukaton alittavaan ja ylittävään osaan;
	IF &maksu > &kertyma - &MaksuKatto THEN DO;

		IF &laji = 5 AND &ika >= &IkaRaja THEN DO;
			IF &erikoissh=1 THEN temp = (&Maksukatto- (&kertyma-&maksu)) + ((&kertyma - &MaksuKatto) / &maksu) * &hoitopv * MIN(LyhytAikKatonJalk*&minf,&LyhytAikKatonJalk);
			ELSE temp =(&Maksukatto- (&kertyma-&maksu)) + ((&kertyma - &MaksuKatto) / &maksu) * &hoitopv * MIN(LyhytAikKatonJalkPTH*&minf,&LyhytAikKatonJalk);
		END;
		ELSE temp = &MaksuKatto - (&kertyma - &maksu);

	END;
	ELSE IF &laji=5 AND &ika >= &IkaRaja THEN DO;
		IF &erikoissh=1 THEN temp= &hoitopv * MIN(LyhytAikKatonJalk*&minf,&LyhytAikKatonJalk);
		ELSE temp = &hoitopv * MIN(LyhytAikKatonJalkPTH*&minf,&LyhytAikKatonJalk);
	END;
	ELSE temp=0;

END;
ELSE temp=&maksu;

IF .<temp<0 THEN &tulos=0;
ELSE &tulos=ROUND(temp,0.01);

%MEND;


*Laitoshoidon ja tehostetun palveluasumisen maksujen simulointimakro, enimmäismäärät

ika=potilaan ikä
laji= hoidon tyyppi
tulot = asiakkaan nettotulot (€/kk)
puoltulot = puolison nettotulot (€/kk)
psyk = psykiatrinen hoito (0/1)
maxkustannus = maksimikustannus per kk (€), yleensä tuotantokustannukset;




%MACRO LaitosHoito(tulos,mvuosi,mkuuk,minf,ika,laji,tulot,puoltulot,vuokra,omav_laake,psyk=0,maxkustannus=6000)/ 
DES = 'Laitoshoidon maksut';
%HaeParam&TYYPPI(&mvuosi, 1, &ASMAKSU_PARAM, PARAM.&PASMAKSU);
%ParamInf&TYYPPI(&mvuosi, &mkuuk, &ASMAKSU_MUUNNOS, &minf);


*Pitkäaikaisen laitoshoidon maksu /NETTOTULO;
IF &laji=1  THEN DO;

	IF NOT &puoltulot OR &tulot < &puoltulot THEN temp= &PitkaLaitosPros1 * &tulot;
	ELSE temp= &PitkaLaitosPros2 * SUM(&tulot, &puoltulot);

	IF SUM(&tulot,-temp) < &PitkaLaitosSuojaOsa THEN temp=SUM(&tulot,-&PitkaLaitosSuojaOsa);
	
	IF &ika < &IkaRaja THEN temp=0;
END;

*Tehostettu eli ympärivuorokautinen palveluasuminen /NETTOTULO;
ELSE IF &laji=2 THEN DO;
	IF NOT &puoltulot OR &tulot < &puoltulot THEN temp= &PitkaLaitosPros1 * MAX(0, SUM(&tulot,&vuokra,-&omav_laake/12));
	ELSE temp= &PitkaLaitosPros2 * MAX(0, SUM(&tulot, &puoltulot,-&vuokra,-&omav_laake/12));

	IF SUM(&tulot,-temp,-&vuokra,-&omav_laake/12) < 165 THEN temp=max(0,SUM(temp,-sum(165,-max(0, sum(&tulot,-temp,-&vuokra,-&omav_laake/12)))));  

END;

*Ateriamaksu+vuokra;

ELSE IF &laji=5 THEN DO;
	IF &psyk=1 THEN temp=&LyhytAikLaitosPsyk;
	ELSE temp=&LyhytAikLaitosMuu;
END;

ELSE IF &laji=6 THEN temp= &KuntHoitMaksu;


IF .<temp<0 THEN &tulos=0;
ELSE &tulos=ROUND(MIN(&maxkustannus, temp),0.01);
drop temp;

%MEND;
