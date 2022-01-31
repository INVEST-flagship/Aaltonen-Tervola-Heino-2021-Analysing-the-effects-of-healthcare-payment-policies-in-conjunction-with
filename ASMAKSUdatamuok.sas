
*Makro muodostaa laitoshoidon maksujen datan;

%MACRO LaitHoitData(AVUOSI);
	%let avuosi=2017;

	data asuminen;
		set sote&avuosi..soshilmo_&AVUOSI._shnro sote&avuosi..hilmo_&AVUOSI._shnro;
		where pala in ('1','5','6','31','32','33','34','81','82','84','85');
		alku=datepart(tupva);
		loppu=datepart(lpvm);
		test=timepart(tupva);

		*if day(loppu) NE 31 or month(loppu) NE 12;
		*if ilaji in (2,4) then loppu='31dec2016'd;
		*Mik‰ on pala=8?;
		laji=input(pala,best21.);

		*Laitoshuolto, palveluasuminen, (kotihoito);
		if laji in (1,5,31,33,41) then
			laji2=1;
		else if laji in (32,34,42,84,85) then
			laji2=2;
		else if laji in (81,82) then
			laji2=3;
		else if laji=6 then
			laji2=6;
		pitkapaatos=(pitk='K');

		if ea NOT IN ('98','') THEN	psyk=(substr(ea,1,1)='7');

		keep hnro psyk alku ilaji loppu laji2 pitkapaatos laji kustannus tupva test;
		format loppu alku ddmmyy10. laji laji. laji2 lajiryhma.;
	run;

	*Seuraavassa poistetaan p‰‰llekk‰isi‰ jaksoja ja yhdistet‰‰n limitt‰isi‰;
	proc sort data=asuminen nodupkey;
		by hnro alku loppu;
	run;

	proc sort data=asuminen;
		by hnro laji2 alku loppu;
	run;

	data asuminen;
		set asuminen;
		by hnro;

		if hnro NE lag(hnro) or alku>lag(loppu) or laji2 NE lag(laji2) then
			jakso+1;
	run;

	proc summary data=asuminen nway;
		class jakso;
		id hnro laji2 psyk kustannus laji pitkapaatos;
		output out=asuminen2 min(alku)= max(loppu)=;
	run;

	data asuminen2;
		set asuminen2(drop=jakso);
		by hnro;

		if hnro NE lag(hnro) or alku>lag(loppu) or laji2 NE lag(laji2) then
			jakso+1;
	run;

	proc summary data=asuminen2 nway;
		class jakso;
		id hnro laji2 psyk kustannus laji pitkapaatos;
		output out=asuminen2 min(alku)= max(loppu)=;
	run;

	data asuminen2;
		merge asuminen2(in=a drop=jakso _type_ _freq_) pohjadat.rek&avuosi(keep=hnro lhtm kelapu ehtm hvamtuk ikavu ikakk);
		by hnro;

		if a;

		loppu=min(loppu,"31dec&AVUOSI"d);
		hoitopv=loppu-alku+1;
		hoitopv&AVUOSI=loppu-max(alku,"01jan&AVUOSI"d)+1;

		if hoitopv&AVUOSI>0;

		IF laji=6 AND (lhtm OR hvamtuk OR ehtm OR kelapu) THEN
			laji2 = 6;
		ELSE IF laji=6 THEN
			laji2=1;
		DROP lhtm hvamtuk kelapu ehtm;* laji;
	run;

	%include "&LEVY&KENO&HAKEM&KENO.DATA&KENO.POHJADAT&KENO.HILMO_kotihoitoimpu.sas";
	%kotihoito_impu(&AVUOSI);


	*T‰ss‰ simuloidaan jakoa pitk‰- ja lyhytaikaisen laitoshoidon v‰lill‰. 
	Jos henkilˆll‰ on pitk‰aikaisen laitoshoidon p‰‰tˆs niin heti jakson alusta. Muuten 3kk:n j‰lkeen (raja kovakoodattu);

	DATA laitos; SET asuminen2; 
		WHERE laji2 in (1,6);

		IF pitkapaatos OR intck('month',alku,"31DEC%EVAL(&AVUOSI-1)"d,'c') >= 3 THEN pitkaik = hoitopv&AVUOSI;

		ELSE IF intck('month',alku,loppu,'c') >= 3 THEN DO;
			lyhytaik = intnx('month',alku,3,'same') - alku - (hoitopv - hoitopv&AVUOSI);
			pitkaik = hoitopv&AVUOSI - lyhytaik;
		END;

		ELSE IF laji2=1 THEN lyhytaik = hoitopv&AVUOSI;
		ELSE IF laji2=6 THEN kunthoit = hoitopv&AVUOSI;

		IF lyhytaik and pitkaik THEN DO; lyhytloppu=alku+lyhytaik; pitka_alku=lyhytloppu+1; END;
		FORMAT lyhytloppu pitka_alku ddmmyy10.;
	RUN;


	PROC SORT DATA=laitos; BY hnro alku loppu ikavu ikakk kustannus psyk laji2 lyhytloppu pitka_alku;
	PROC TRANSPOSE DATA=laitos out=laitos; BY hnro alku loppu ikavu ikakk kustannus psyk laji2 lyhytloppu pitka_alku;
		var lyhytaik pitkaik kunthoit; RUN;


	DATA laitos; SET laitos; WHERE col1; 
		IF _name_='lyhytaik' THEN DO; 
			IF laji2=1 THEN laji2=5; 
			*ELSE IF laji2=2 THEN laji2=28; *Lyhytaikainen palveluasuminen (jos 2 poimittu ylemp‰n‰);
			if lyhytloppu THEN loppu=lyhytloppu; 
		END;
		ELSE IF _name_='kunthoit' THEN laji2=6;
		ELSE DO; 
			IF laji2=6 THEN laji2=1; if pitka_alku THEN alku=pitka_alku; 
		END;

		DROP _name_ lyhytloppu pitka_alku;
	RUN;

*T‰ss‰ muutetaan laitoshoidon jaksot kk-tason riveiksi (toimeentulotukilaskennan takia);
		
	%macro kuukloop;
	%do kuuk=1 %to 12;
		day=mdy(&kuuk,1,&AVUOSI);
		if month(alku)=month(loppu) and year(alku)=year(loppu) then do;
			if month(alku)=month(day) then mon&kuuk=loppu-alku+1;
			else mon&kuuk=0;
		end;
		else if alku<=day<=loppu or (year(alku)=&AVUOSI and month(alku)=month(day)) then do;
			if year(alku)=&AVUOSI and month(alku)=month(day) then mon&kuuk=INTNX('month',alku,0,'end')-alku+1;
			else if year(loppu)=&AVUOSI and month(loppu)=month(day) then mon&kuuk=day(loppu);
			else if year(alku) <&AVUOSI OR month(alku) NE month(day) then mon&kuuk=day(INTNX('month',day,0,'end'));
		end;
		else mon&kuuk=0;
	%end;
	%mend;

	data laitos; set laitos; 

	%kuukloop;

	run; 
	proc sort data=laitos; by hnro alku loppu ikavu ikakk psyk laji2 kustannus; 
	proc transpose data=laitos out=laitos(where=(col1)); by hnro alku loppu ikavu ikakk psyk laji2 kustannus; var mon1-mon12; run;

	data laitos; set laitos;
		kk=input(substr(_name_,4,2),best21.);

		IF laji2=1 THEN LAITOS=1; 
		IF laji2=5 THEN DO;

			IF loppu-alku+1>30 THEN LYHHOITO30=1;

			IF ikavu<18 THEN alle18pv= col1;
			ELSE IF ikavu=18 THEN alle18pv=MAX(0, ((12-ikakk)-kk)*30); 

		END;

		BY HNRO;
		IF first.hnro then alle18kerty=0;
		ALLE18KERTY + ALLE18PV;

		RENAME COL1=HOITOPV&AVUOSI;
		DROP _NAME_ ALLE18PV;
	run;


%MEND;

*Makro muodostaa tasasuuruisten maksujen datan;
%MACRO TASAMAKSUDATA(AVUOSI);


	data temp; set sote2017.HILMO_TMP2017; format isoid best32.; 
	proc sort data=temp NODUPKEY; by isoid TMPKOODI; run;
	proc sort data=sote2017.HILMO_2017_SHNRO out=tasamaksu ; *where pala>'89'; by isoid; run;
	data tasamaksu; set tasamaksu; format isoid best32.; run;
	
	data temp3; merge tasamaksu temp(in=b); by isoid; if not b and pala='93'; 
	kk=month(datepart(tupva));
	run;
	proc summary nway; class hnro ea paltu kk; output out=temp3; run;
	proc summary nway; class hnro ea paltu; output out=temp3(where=(kk_mean>=3)) mean(_freq_)=kk_mean; run;
	data temp3; set temp3; hoitopv2=kk_mean*_freq_; run;
	

	data temp; merge tasamaksu(in=a) temp(in=b); by isoid; if A AND b; 
	IF tmpkoodi IN ('ZY020','WZB00') or SUBSTR(TMPKOODI,1,3) IN ('ZYY','ZYC') THEN PUH=1; ELSE PUH=0;

	run;
	PROC SORT DATA=TEMP; BY HNRO; RUN;

	proc freq data=temp noprint; WHERE NOT PUH; table hnro*pala*tmpkoodi*paltu /out=temp2;
	data temp2; set temp2;
	if (substr(tmpkoodi,1,3) IN ('TK8','AX0','EX0','HA0','KE0','WXQ','AA4','WQ0','4AB','KCW','TKW','XA8','2AX') 
	OR substr(tmpkoodi,1,2) IN ('R2','R4','WA','WF','ZX','WB','WC','WD','WE','RJ') OR tmpkoodi IN ('Z2445','Z3226')) 

	AND PALA='93' AND COUNT>=3 THEN SARJA =1; ELSE SARJA=0;*,;

	IF TMPKOODI='Z3231' THEN HOITAJA=1; ELSE IF SUBSTR(TMPKOODI,1,2) IN ('Z2','Z3') THEN HOITAJA=2; ELSE HOITAJA=0;
	IF TMPKOODI='Z2445' THEN PSYK=1;
	RUN;
	PROC SORT DATA=TEMP2; BY HNRO PALA paltu TMPKOODI;
	PROC SORT DATA=TEMP; BY HNRO PALA paltu TMPKOODI;
	DATA TEMP2; MERGE TEMP2 TEMP; BY HNRO PALA paltu TMPKOODI;
	IF SARJA THEN HOITOPV=COUNT;
	RUN;
	proc summary data=temp2 nway; class isoid; output out=temp2(where=(hoitaja=1 or puh OR SARJA) drop=_type_ _freq_) max(PSYK HOITOPV SARJA HOITAJA PUH)=; 
	run;

	data tasamaksu; merge tasamaksu(in=a where=(pala in ('2','83','91','92','93','94'))) temp2; 
	by isoid;
	if a;
	if puh OR (pala='91' and ea IN ('98','15Y')) THEN DELETE;

	if NOT PSYK AND ea NOT IN ('98','') THEN
			psyk=(substr(ea,1,1)='7');


		*laji=input(pala,best21.);
		alku=datepart(tupva);
		loppu=datepart(lpvm);

		if pala='2' THEN
			laji2=7;

		if pala>'89' then
			laji2=9;

		if pala='83' then
			laji2=8;
		
		IF NOT SARJA THEN SARJA=0;
		IF SARJA THEN laji2=12;
		IF laji2=9 AND HOITAJA THEN laji2=9.5;

		if year(alku)=&avuosi;
		format loppu alku ddmmyy10. laji2 lajiryhma.; drop puh;
	run;
	
	proc sort data=tasamaksu nodupkey; by hnro ea paltu alku;
	data tasamaksu; merge tasamaksu(in=a) temp3(in=b keep=hnro ea paltu hoitopv2); by hnro ea paltu;
	if a;
	if b and pala='93' then do;
		sarja=1;
		hoitopv=sum(hoitopv,hoitopv2);
		laji2=12;
	end;
	ea2=substr(ea,1,2);
	run;
	/*proc summary data=tasamaksu; class ea2; where pala='93'; output out=test mean(sarja)=; run;*/

	*Poistetaan laitoshoidon kanssa p‰‰llekk‰iset avohoidon k‰ynnit (huom. t‰ytyy luoda ensin laitoshoidon data);
	proc sql noprint;
		create table tasamaksu as
			select b.*, (a.alku<=b.alku<=a.loppu) as paalle
				from asuminen2(where=(laji2 IN (1,5,6))) as a
					right join tasamaksu as b
						on a.hnro=b.hnro;
		create table tasamaksu(drop=paalle) as
			select max(hnro) as hnro ,max(alku) format=ddmmyy10. as alku,max(psyk) as psyk, max(laji2) format=lajiryhma. as laji2, max(hoitopv) as hoitopv, max(paalle) as paalle
			from tasamaksu
				group by isoid
					having not paalle | laji2=7
						order by hnro;
	quit;

	
	data temp; set sote2017.symatka_ao_shnro sote2017.symatka_shnro; where kulkuneu in ('A','H'); 
	keep hnro matpv; rename matpv=alku;
	run;
	proc sort nodupkey; by hnro alku; run; 

	proc sort data=tasamaksu; by hnro alku;
	data tasamaksu; merge tasamaksu(in=a) temp(in=b); by hnro alku; if a; if b then delete; run;



	data temp; set sote2017.HILMO_2017_SHNRO;
	where PALA = '91' AND ea IN ('98','15Y'); 
	format isoid best32.;
	rename tupva=kaynti_alkoi isoid=tapahtuma_tunnus;
	kaynti_palvelumuoto='T11' ;
	ammattiryhma ='A10';
	psyk=0;
	keep hnro isoid tupva kaynti_palvelumuoto ammattiryhma psyk;
	run;



	*Perusterveydenhuollon l‰‰k‰rik‰ynnit, fysioterapia ja suun terveydenhuolto;

	data tasamaksu_perus;
	set %do i=1 %to 6; sote&avuosi..Avohilmo_&AVUOSI._&i._shnro  
		(where= (not peruutus_syy and kaynti_kavijaryhma and ((kaynti_palvelumuoto='T11' AND ammattiryhma IN ('A10','A20')) OR kaynti_palvelumuoto IN ('T60','T51'))
			and kaynti_yhteystapa ='R10')) %end; temp;
		alku=datepart(kaynti_alkoi);

		IF year(alku)=&AVUOSI;
		lasupyh_yo=(weekday(alku) in (1,7));

		if alku = MDY(1,1,&AVUOSI) or alku = MDY(5,1,&AVUOSI) or alku = MDY(06,19,&AVUOSI) or alku = MDY(01,06,&AVUOSI) or alku = MDY(12,6,&AVUOSI) or alku = MDY(12,25,&AVUOSI) or alku = MDY(12,24,&AVUOSI) or alku = MDY(12,26,&AVUOSI) then
			lasupyh_yo=1;

		if timepart(kaynti_alkoi) and (hour(timepart(kaynti_alkoi))>=20 or hour(timepart(kaynti_alkoi))<8) then
			lasupyh_yo=1;
		format alku ddmmyy10.;

		IF kaynti_palvelumuoto='T11' AND ammattiryhma IN ('A10','A20') THEN
			DO;
				IF ammattiryhma='A10' THEN laji2=10;
				ELSE laji2=27;
			END;
		ELSE IF kaynti_palvelumuoto='T51' THEN DO;
			laji2=11;
			hoitopv&AVUOSI=1; END;
		ELSE IF kaynti_palvelumuoto='T60' THEN DO;
			laji2=26;
			hoitopv&AVUOSI=1; END;

		tapahtuma_tunnus2=tapahtuma_tunnus; if kaynti_palvelumuoto NE 'T60' THEN tapahtuma_tunnus2=alku; 
		keep hnro psyk alku asiakas_kotikunta lasupyh_yo laji2 kaynti_alkoi tapahtuma_tunnus tapahtuma_tunnus2 ammattiryhma;
	run;

	proc sort data=tasamaksu_perus;
		by hnro laji2 alku ammattiryhma;
	run;

	*Dropataan saman p‰iv‰n aikana tapahtuneet identtiset k‰ynnit;
	proc sort data=tasamaksu_perus nodupkey;
		by hnro laji2 tapahtuma_tunnus2;
	run;
	proc sort data=tasamaksu_perus(drop=tapahtuma_tunnus2);
		by hnro asiakas_kotikunta laji2 ammattiryhma lasupyh_yo alku;
	run;

	*Suun terveydenhuollon toimenpiteiden luokittelu;
	proc sort data=sote&avuosi..suu_tmp&avuosi out=suu;
		by tapahtuma_tunnus;

	data suu;
		set suu;

		If toimenpide in ('EB1AA','EB1CA','EB1SA') then
			laji2=13;
		ELSE IF toimenpide in ('EB1HA','EB1JA') then
			laji2=14;
		ELSE IF toimenpide in ('SCA01','SCA02','SCA03','SCE00') then
			laji2=15;
		ELSE IF toimenpide in ('SPF20','SPF30') then
			laji2=16;
		ELSE IF toimenpide in ('SPF40','SPF50','SPF60') then
			laji2=17;
		ELSE IF toimenpide in ('SPD00','SPD05','SPD10','SPD20','SPE10','SPE90') then
			laji2=18;
		ELSE IF toimenpide in ('SPC10','SPC20','SPC25','SPC30','SPC35','SPC40','SPC45') then
			laji2=19;
		ELSE IF toimenpide in ('SPE00','SPE05') then
			laji2=20;
		ELSE IF toimenpide in 
			('SXA20','TEA10','TEC00','TED10','TEE00','TEH00','TEJ00','TEM00','TEN00','TEW99','WX105','WX110','WX290','WYA00','WZA00','WZB00',
			'SBA10','SBA20','SXA10','TEL00','EAA00','SAA01','SAD01','SCA01','SDA01','SHA01','SJB30','SJC01','SJC20','SJF01','SPB00','SPB20','SPC60',
			'SXB00','SXC05','TEL40','WYA30','WZA90','SAA01','SAB01','SAD01','SBA10','SBA20','SCA01','SCA02','SCA03','SCE00','SDA01',
			'SFC01','SHA01','SJB30','SJC01','SJC20','SJF01','SJX11','SPB00',
			'SPB20','SPC60','SXA10','SXA20','SXB00','EAA00','TEA10','TEC00','TED10',
			'TEE00','TEH00','TEJ00','TEL00','TEL40','TEM00','TEN00') 
			then
			laji2=21;
		ELSE IF toimenpide in 
			('EAA10','EAB00','ECA10','ECA60','ECB00','EKC00','EKC10','SAB03','SBA00','SBB00','SBB10','SCA02','SCE00','SDA02','SDD01','SFA00',
			'SFC92','SGA01','SGB10','SGC00','SGC10','SGD01','SJC10','SPA20','TED00','EBA00','EBA30','EBU00','ECA20','ECU05','ECW05',
			'EHA00','EHC00','EJC00','EKA00','SAA02','SAA03','SAD02','SCA03','SDC10','SFA10','SGA02','SGB00','SGD00','SHA02','SJB60',
			'SJC40','SPF00','SPF20','SXB10','TEA00','TEG00','WX002','WYA20','YEA00','YNA09','SAA02','SAB02','SAC01','SAD02','SBA00','SBB00',
			'SBB10','SDA02','SDC10','SDD01','SDE02','SFA00','SFA10','SFC92','SGA01',
			'SGA02','SGB00','SGB10','SGC00','SGC10','SGD00','SGD01','SHA02','SJB60',
			'SJC10','SJC40','SJX21','SXB10','SXC02','EAA10','EAB00','EBA00','EBA30',
			'EBU00','ECA10','ECA20','ECA60','ECB00','ECU05','ECW05','EHA00','EHC00',
			'EJC00','EKA00','EKC00','EKC10','TEA00','TED00','TEG00','YEA00','YNA09') 
			then
			laji2=22;
		ELSE IF toimenpide in 
			('ECW06','EDA00','EDA10','EEA00','EEA10','EHA10','EJA10','EJB00','EKA10','SDA03','SDD02','SGA03','SGB20','SHA03','SJB00','SJD00',
			'SJD10','SJD40','SPA00','SPB10','SPF40','EAA20','EAA30','EAA99','EAB10','EBB05','ECA30','ECB05','ECB17','ECB20','ECU06',
			'EFA40','EJC20','ELA00','ELC30','SDC20','SFA20','SFB10','SJC02','SJC50','SJD20','SJD50','SJE90','SJX00','SPB15',
			'SPF10','EBA05','EBA20','EBB15','ECA00','ECB10','ECB50','EGU00','SDA04','SDA12','SDC30','SDD03','SFA30','SFC00',
			'SGA04','SGA06','SGB30','SGC20','SGC40','SHA04','SJB10','SPA05','SPB25','SPC45','SPC50','SPF30','SPF50','SPF60','SAA03','SAA04','SAC02','SAC03','SDA03','SDA04','SDA12','SDC20','SDC30','SDD02','SDD03',
			'SDE03','SDE04','SFA20','SFA30','SFB10','SFC00','SGA03','SGA04','SGA06','SGB20','SGB30',
			'SGC20','SGC40','SHA03','SHA04','SJB00','SJB10','SJC02','SJC50','SJD00','SJD10','SJD20',
			'SJD40','SJD50','SJE90','SJX00','SPB10','SPB15','SPB25','SPC50','SPF00','SPF10','SPF40',
			'SPF50','SPF60','SXC03','SXC04','EAA20','EAA30','EAA99','EAB10','EBA05','EBA20','EBB05',
			'EBB15','ECA00','ECA30','ECB05','ECB10','ECB17','ECB20','ECB50','ECW06','EDA00','EDA10',
			'EEA00','EEA10','EFA40','EGU00','EHA10','EJA10','EJB00','EJC20','EKA10','ELA00','ELC30','WCZ05') 
			then
			laji2=23;
		ELSE IF toimenpide in 
			('EAB20','EAB99','EAW99','EBA15','EBA40','EFB45','EGA05','EGA10','EJA20','EKB00','EKB99','EKC20','ELA10','ELA20',
			'EWA00','SFA40','SFB20','SGA05','SGC50','SJD30','SPB28','ECA40','ECB15','EFB10','EJA00','EJB10','EJB20','ELB10','ELC00',
			'ELC40','ELC50','ELC99','SDA05','SDA13','SDC40','SDD10','SGA07','SGC30','SHB00','SPB30','EAB30','SBA10','EBA45','EBB00',
			'EBB11','EBB20','EBB40','ECA35','ECA50','ECU00','EDB30','EEC30','EFA50','EFB50','EGA00','EHB00','EHC20','EHU00','EJC40',
			'EKC30','ELA30','ELB20','ELC60','SJC03','SPA10','SPC40','YEA05','SDA05','SDA13','SDC40','SDD10','SFA40','SFB20','SGA05',
			'SGA07','SGC30','SGC50','SHB00','SJC03','SJD30','SPB28','SPB30','SPF20','SPF30',
			'EAB20','EAB30','EAB99','EAW99','EBA10','EBA15','EBA40','EBA45','EBB00','EBB11',
			'EBB20','EBB40','ECA35','ECA40','ECA50','ECB15','ECU00','EDB30','EFA50','EFB10',
			'EFB45','EFB50','EGA00','EGA05','EGA10','EHB00','EHC20','EHU00','EJA00','EJA20',
			'EJB10','EJB20','EJC30','EJC40','EKB00','EKB99','EKC20','EKC30','ELA10','ELA20',
			'ELA30','ELB10','ELB20','ELC00','ELC40','ELC50','ELC60','ELC99','EWA00','YEA05') 
			then
			laji2=24;
		ELSE IF toimenpide in 
			('EBB10','ECB40','EEC35','SDA14','SDC50','SFB30','SFB40','SPC10','SPC20','SPC30','SPC35','SPD00','SPE90','EBA12','EBB50',
			'ECA55','ECA70','ECB30','ECB60','ECB65','EDC32','EDC34','EEC20','EFA10','EGA20','EGB00','EGB10','EGB99',
			'EGC00','EGC10','EHC10','ELB00','ELB30','EWE00','EWW99','SPC25','SPD05','SPD10','SPD20','SPE00','SPE10',
			'EDB00','EDC00','EDC05','EDC10','EDB00','EDC00','EDC05','EDC10','EDC15','EDC20','EDC25','EDC30','EDC31',
			'EDC36','EDC38','EDC42','EDC50','EDC55','EEB00','EEC00','EEC05','EEC25','EEC40','EFA20','EFB30','EFB40',
			'EFB60','EGC20','EHC40','EJV30','SPE05','EDB20','EDC45','EEC01','EEC02','EEC10','EEC16','EEC42','EEC45',
			'EGC30','EDB10','EEB20','EEC15','EFB20','EHC30','EHC50','EHC60','ELB40','ELB50') then
			laji2=25;

		if not laji2 then
			delete;
		drop toimenpide toimenpide_hammas;
	run;

	

	proc sort data=tasamaksu_perus;
		by tapahtuma_tunnus;
	run;
	data tasamaksu_perus;
		merge tasamaksu_perus(in=a) suu;
		by tapahtuma_tunnus;

		if a;
		laakari=(ammattiryhma IN ('A10','A40'));

		IF 12<laji2<26 THEN
			DO;
				IF FIRST.tapahtuma_tunnus THEN
					hoitopv&AVUOSI=1;
				ELSE hoitopv&AVUOSI=.;
			END;
		kuntanro=input(asiakas_kotikunta, best21.);

		drop kaynti_alkoi ammattiryhma asiakas_kotikunta;
	run;
	proc sort data=tasamaksu_perus; by kuntanro; run;
	data tasamaksu_perus; merge tasamaksu_perus(in=a) param.kuntashp(keep=kuntanro tk_makkerrat); 
	by kuntanro; if a;
	if not tk_makkerrat then tk_makkerrat=3;

	run;

*Poistetaan laitoshoidon kanssa p‰‰llekk‰iset avohoidon k‰ynnit (huom. t‰ytyy luoda ensin laitoshoidon data);
	proc sql noprint;
		create table tasamaksu_perus as
			select b.*, (a.alku<=b.alku<=a.loppu) as paalle
				from asuminen2(where=(laji2 IN (1,5,6))) as a
					right join tasamaksu_perus as b
						on a.hnro=b.hnro;
		create table tasamaksu_perus(drop=paalle) as
			select max(hnro) as hnro ,max(alku) format=ddmmyy10. as alku, max(laakari) as laakari, max(laji2) format=lajiryhma. as laji2, max(lasupyh_yo) as lasupyh_yo,max(tk_makkerrat) as tk_makkerrat, 
				max(hoitopv&AVUOSI) as hoitopv&AVUOSI, max(paalle) as paalle
			from tasamaksu_perus
				group by tapahtuma_tunnus,jarjestys
					having not paalle | laji2=7;
	quit;



	data pohjadat.asmaksu&avuosi;
		set asuminen2(where=(laji2 not in (1,6))) kotihoito2 laitos tasamaksu tasamaksu_perus;
		drop laji; if not kk then kk=month(alku);
	run;
	

	proc sort data=pohjadat.asmaksu&AVUOSI;
		by hnro laji2 alku;
	run;

	data pohjadat.asmaksu&avuosi;  set pohjadat.asmaksu&AVUOSI;
	by hnro laji2;
	if laji2 in (27,10,11) then do;
		
		if first.hnro or first.laji2 then
			test=0;
				test+1;
				hoitopv2017=test;
	end;
	DROP TEST;
	run;

	proc sort data=startdat.start_asmaksu out=temp nodupkey; by hnro;
	data pohjadat.asmaksu&avuosi; merge pohjadat.asmaksu&avuosi(in=a) temp(keep=hnro kattonro); by hnro; if a; run;

	proc sort data=pohjadat.asmaksu&AVUOSI;
		by hnro;
	run;
	
%MEND;


*Makro muodostaa yksikˆn, jonka perusteella maksukatto lasketaan. 
Lapset lasketaan samaan kattoon sen vanhemman kanssa, jolla enemm‰n maksuja;

%MACRO kattonro(AVUOSI);
	/*
	data pohjadat.rek_elat&AVUOSI; set pohjadat.rek&AVUOSI;
	if not maksvuok and atem then maksvuok=ROUND(atem/12,0.01); run;
		*/
	PROC SORT DATA=TEMP.&TULOSNIMI_AS;
		BY HNRO;

	DATA KATTONRO;
		MERGE TEMP.&TULOSNIMI_AS(IN=A) POHJADAT.REK&AVUOSI(KEEP= HNRO AITI ISA JASEN);
		BY HNRO;

		IF A;

		IF ika>18 THEN
			DO;
				AITI=.;
				ISA=.;
			END;
	RUN;

	proc summary data=KATTONRO nway;
		class knro;
		output out=KATTONRO2 max(aiti isa)=;
	run;

	data KATTONRO;
		merge KATTONRO(drop=aiti isa) KATTONRO2;
		by knro;

		if jasen=aiti then
			asma_aiti=TASAMAKSU;

		if jasen=isa then
			asma_isa=TASAMAKSU;

	proc summary data=KATTONRO nway;
		class knro;
		output out=KATTONRO2 sum(asma_aiti asma_isa)=;
	run;
	proc sort data=pohjadat.asmaksu&AVUOSI; by hnro;
	data pohjadat.asmaksu&AVUOSI;
		merge pohjadat.asmaksu&AVUOSI(in=a) pohjadat.rek&AVUOSI(keep=hnro knro ikavu ikakk isa aiti jasen);
		by hnro; if a; 
		
		run;
	proc sort data=pohjadat.asmaksu&AVUOSI; by knro; run;
	data pohjadat.asmaksu&AVUOSI;
		merge pohjadat.asmaksu&AVUOSI(in=a) kattonro2(keep=knro asma_aiti asma_isa);
		by knro; if a;

		if ikavu<18 then
			do;
				if asma_aiti< asma_isa then
					kattonro=knro*10+isa;
				else kattonro=knro*10+aiti;
			end;
		else kattonro=knro*10+jasen;
		drop asma_aiti asma_isa knro isa aiti jasen ikavu ikakk;
	run;

%MEND;