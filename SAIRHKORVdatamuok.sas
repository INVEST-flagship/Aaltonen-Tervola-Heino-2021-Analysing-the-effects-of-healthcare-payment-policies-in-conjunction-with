

*Muodostetaan yksityisen terveydenhuollon maksujen käyntidata raakadatoista;

data pohjadat.yksterv2017; retain hnro laji2 maksukk ykor ttekno toimk ;

set sote2017.laakarinpalkkiot_shnro(keep=hnro tun v4kk toimk ttekno korv  kust akoro ekoro)
sote2017.TUTKIMUSJAHOITO_SHNRO(keep=hnro tun toimk v4kk ttekno korv kust kkoro kerrat);
WHERE KORV>=0;

erikkoro=(ekoro='E');
aikakoro=(akoro='100');
kotikoro=(kkoro NE '');

IF tun='LP' THEN laji2=1;
ELSE IF tun IN ('LH','HA','LR') THEN laji2=2;
ELSE IF tun IN ('HS') THEN laji2=2.1;
ELSE IF tun IN ('T','FY') THEN laji2=3;


if kerrat=. then kerrat=1;

IF LAJI2 NE 3 THEN ttekno=.;

maksukk=INPUT(SUBSTR(V4KK,5,2),best21.);
OMAV_DATA = SUM(kust,-korv);

ykor=6.6745;

rename korv=KORV_DATA;
drop ekoro akoro kkoro tun V4KK;
format laji2 sairkorvlaji.;
run;
PROC SORT DATA=pohjadat.yksterv2017; by toimk laji2; run;




*Muodostetaan yksityisen terveydenhuollon maksujen taksadata raakadatoista;

data PYKSTAKSA;  retain laji2 koodi tvoimpv tloppv taksa;
set sote2017.szhinta_sisu; 
taksa=taksa/100; format taksa 10.2; 
rename koodi=toimk;

IF laji='LP' THEN laji2=1;
ELSE IF laji IN ('HL') THEN laji2=2;
ELSE IF laji IN ('HS') THEN laji2=2.1;
ELSE IF laji IN ('TH') THEN laji2=3;
ELSE DELETE;

IF tLOPPV=. OR year(tloppv)<2010 THEN DELETE;
IF tLOPPV<tVOIMPV THEN DELETE;

keep taksa koodi tvoimpv tloppv laji2 hjno;
run;
proc sort data=pykstaksa; by toimk laji2 descending hjno; run;
data pykstaksa; set pykstaksa; 
if toimk=lag(toimk) and laji2=lag(laji2) and tloppv> lag(tvoimpv) then DO;
	IF YEAR(tLOPPV)=9999 THEN DELETE;
	ELSE tloppv=intnx('day',lag(tvoimpv),-1);
END;

if (toimk='JJ2AT' and hjno=6) or (toimk='YA1CD' and hjno=2) then delete;


 run;
proc summary data=pykstaksa nway idmin; class toimk laji2; id tvoimpv taksa hjno;
output out=temp(where=(tvoimpv>"31dec2010"d)); run;
proc sort data=pykstaksa; by toimk laji2 hjno; run;
proc sort data=temp; by toimk laji2 hjno; run;
data pykstaksa; merge pykstaksa temp(keep=hjno laji2 toimk in=a); by toimk laji2 hjno;
if a then tvoimpv="31jan2010"d;
run;
data param.pykstaksa; set pykstaksa; drop hjno; run;




*Muodostetaan yksityisen matkakorvauksien pohjadata raakadatasta;


DATA POHJADAT.MATKA2017; retain hnro MATPV; SET SOTE2017.SYMATKA_SHNRO SOTE2017.SYMATKA_AO_SHNRO; 

maksupv= MDY(INPUT(SUBSTR(V4KK,5,2),best21.),1,INPUT(SUBSTR(V4KK,1,4),best21.));
maksukk= INPUT(SUBSTR(V4KK,5,2),best21.);

OMAV_DATA=SUM(kusty,-korv);
*if kulkuneu='O' THEN kerrat=ROUND(kusty/kust);*omav/matlkm;
*else; *kerrat=omav;
RENAME kusty=kust_data;
laji=4;

IF kulkuneu IN ('L','T','I','Y','P','Å','Z','W') THEN KULKUN=1;
ELSE IF kulkuneu='A' THEN KULKUN=2;
ELSE IF kulkuneu='O' THEN KULKUN=3;
ELSE KULKUN=99;

IF TUN IN ('MB','MW') THEN TAKSIKORO=1;
IF TUN='MY' THEN YOPYMISRAHA=1;

ykor=6.6745;

RENAME KORV=KORV_DATA;
keep hnro tun OMAV_DATA kilom korv omav maksukk LAJI matlkm MATPV maksupv ykor TAKSIKORO YOPYMISRAHA KULKUN ;
format laji sairkorvlaji. maksupv ddmmyy10.;
run;



