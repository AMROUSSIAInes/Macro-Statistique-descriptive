data statdesc ; format Variables $2000. label $2000. Items $1000. Valeurs $50. Bornes $30. Miss $30. ; run ;
%put 'SYNTAXE : %statdesc(table, variable, quali,bin , n , condition)' ;
%macro statdesc(table, variable, label, quali,bin ,  n ,condition) ;

	data table ; set &table. ; where &condition. ; run ;
	%put CALCUL DES EFFECTIFS DANS UN SOUS ECHANTILLON AVEC LA CONDITION : &condition. ;

%if &quali=1 %then %do ;

%if &bin.=0 %then %do;	
		proc freq data=table noprint ;
			table &variable. / out=freq ;
			where &condition. ;
		run ;
		data missfreq (keep=missing);
			set freq;
			if _N_=1;
			if PERCENT=. then missing=COUNT;
			else missing=0;
		run;	
		data freq ; set freq ;
			if PERCENT=. then delete;
		run ;	
		data freq; 
			merge freq missfreq; 
			pourc=round((missing*100/&n.),.1);
			Miss=missing!!" ("!!compress(pourc) !!")"; 
			Variables="&variable." ;
			Items=put(&variable.,$30.) ;
			Valeurs=count!!" ("!!compress(round(percent,.1))!!")" ;
			if _N_=1 then label="&label";
			keep Variables Items Valeurs label Miss;
		run;
	%end;
	%else %if &bin.=1 %then %do;
		proc freq data=table noprint ;
			table &variable. / out=freq ;
			where &condition. ;
		run ;
		data missfreq (keep=missing);
			set freq;
			if _N_=1;
			if PERCENT=. then missing=COUNT
			else missing=0;
		run;	
		data freq ; set freq ;
			if &variable.=1;
		run ;	
		data freq; 
			merge freq missfreq; 
			pourc=round((missing*100/&n.),.1);
			Miss=missing!!" ("!!compress(pourc) !!")"; 
			Variables="&variable." ;
			Items=put(&variable.,$30.) ;
			Valeurs=count!!" ("!!compress(round(percent,.1))!!")" ;
			if _N_=1 then label="&label";
			keep Variables Valeurs label Miss;
		run;
	%end;
	data statdesc ; set statdesc freq ; run ;
%end ;
%else %do ;
	proc means data=&table. n nmiss mean std median q1 q3 min max maxdec=2 noprint nonobs ;
		var &variable. ;
		where &condition. ;
	output out=mean
		n(&variable.)=		effectif
		nmiss(&variable.)=	missing
		mean(&variable.)=	moyenne
		std(&variable.)=	ecarttype
		median(&variable.)=	mediane
		q1(&variable.)=		q1
		q3(&variable.)=		q3
		min(&variable.)=	min
		max(&variable.)=	max ;
	run ;
	data mean ; set mean ; n=effectif+missing; pourc=round((missing*100/n),.1);
		Variables="&variable." ;
		Miss=missing!!" ("!!compress(pourc) !!")";
		Valeurs=round(mediane,.1)!!" ["!!compress(round(q1,.1))!!" ; "!!compress(round(q3,.1))!!"]" ;
		Bornes="["!!compress(round(min, 0.1))!!" ; "!!compress(round(max, 0.1))!!"]" ;
		keep Variables Miss Valeurs Bornes label ;
		label Variables="Variables"  Valeurs="Valeurs" Bornes="[Min ; Max]" ;
		if _N_=1 then label="&label";
	run ;
	data statdesc ; set statdesc mean ; if Miss in ("           . (.)", "           0 (0)") then Miss=""; run ;
%end ;

proc datasets lib=work nolist ; delete  table mean freq missfreq; run ; quit ;
	
%mend ;
	
