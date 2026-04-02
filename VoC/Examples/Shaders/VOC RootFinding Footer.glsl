//other global variables
double sqrsamplepixels=double(samplepixels*samplepixels);
double bailout_squared=double(bailout*bailout);
double magnitude,r1,r2,g1,g2,b1,b2,r3,g3,b3,tweenval;
float realiters;
vec4 finalcol,col;
int superx,supery;
double stepx=(xmax-xmin)/resolution.x/double(samplepixels);
double stepy=(ymax-ymin)/resolution.y/double(samplepixels);
int index,colval,colval1,colval2,numroots;
vec3 rootcolors[8];
dvec2 roots[8];
dvec2 z,c,lastz,lastz2,f,d,d2,w,fw,dw,d2w,L,term1,term2,term2Z,term2N;
dvec2 zpow2,zpow3,zpow4,zpow5,zpow6,zpow7,zpow8;
dvec2 wpow2,wpow3,wpow4,wpow5,wpow6,wpow7,wpow8;
double dist0,dist1,logt,log0,log1,floatval;

//orbit trap variables
double trapx,trapy,trapsize,sxmin,sxmax,symin,symax,trapmin,trapmax; 
double stalksradiushigh,stalksradiuslow;
bool trapped;
double trapdist,stalksradius,distpercentage;
double ztot,cx,cy;
int epscolor,iters;


//------------------------------------------------------------
// complex number operations
//------------------------------------------------------------

dvec2 cadd( dvec2 a, dvec2 b ) { return dvec2( a.x+b.x, a.y+b.y ); }
dvec2 csub( dvec2 a, dvec2 b ) { return dvec2( a.x-b.x, a.y-b.y ); }
dvec2 cmul( dvec2 a, dvec2 b )  { return dvec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
dvec2 cdiv( dvec2 a, dvec2 b )  { double d = dot(b,b); return dvec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }
dvec2 csqr( dvec2 a ) { return dvec2(a.x*a.x-a.y*a.y, 2.0*a.x*a.y ); }
dvec2 csqrt( dvec2 z ) { double m = length(z); return sqrt( 0.5*dvec2(m+z.x, m-z.x) ) * dvec2( 1.0, sign(z.y) ); }
dvec2 conj( dvec2 z ) { return dvec2(z.x,-z.y); }
dvec2 cpow (dvec2 c, int p) { dvec2 a=dvec2(1.0,0.0); for (int i = 1; i <= p; i++) a=cmul(a,c); return a; }

//------------------------------------------------------------
// complex number constants
//------------------------------------------------------------

dvec2 c0=dvec2(0.0,0.0);
dvec2 c0point2=dvec2(0.2,0.0);
dvec2 c1=dvec2(1.0,0.0);
dvec2 c2=dvec2(2.0,0.0);
dvec2 c3=dvec2(3.0,0.0);
dvec2 c4=dvec2(4.0,0.0);
dvec2 c5=dvec2(5.0,0.0);
dvec2 c6=dvec2(6.0,0.0);
dvec2 c7=dvec2(7.0,0.0);
dvec2 c8=dvec2(8.0,0.0);
dvec2 c9=dvec2(9.0,0.0);
dvec2 c10=dvec2(10.0,0.0);
dvec2 c12=dvec2(12.0,0.0);
dvec2 c14=dvec2(14.0,0.0);
dvec2 c15=dvec2(15.0,0.0);
dvec2 c16=dvec2(16.0,0.0);
dvec2 c18=dvec2(18.0,0.0);
dvec2 c20=dvec2(20.0,0.0);
dvec2 c28=dvec2(28.0,0.0);
dvec2 c30=dvec2(30.0,0.0);
dvec2 c36=dvec2(36.0,0.0);
dvec2 c42=dvec2(42.0,0.0);
dvec2 c45=dvec2(45.0,0.0);
dvec2 c60=dvec2(60.0,0.0);

//-----------------------------------------------------------------------------------------------
// orbit traps
//-----------------------------------------------------------------------------------------------

void InitOrbitTraps() {
	//center of trap
	trapx=0.0;
	trapy=0.5;
	//set variables based on orbit trap method
	switch (orbitstyle) {
		case 1:
			//circles
			trapsize=0.5;
			break;
		case 2:
			//cross
			trapsize=0.05;
			break;
		case 3:
			//squares
			trapsize=0.4;
			sxmin=trapx-trapsize;
			sxmax=trapx+trapsize;
			symin=trapy-trapsize;
			symax=trapy+trapsize;
			break;
		case 4:
			//rings
			trapmin=0.3;
			trapmax=0.5;
			break;
		case 5:
			stalksradius=0.25;
			cx=0.0;
			cy=0.0;
			stalksradiushigh=0.0;
			stalksradiuslow=0.0;
			//stalks orbit trap radius
			cx = xmin+gl_FragCoord.x/resolution.x*(xmax-xmin)+(stepx*double(superx));
			cy = ymin+gl_FragCoord.y/resolution.y*(ymax-ymin)+(stepy*double(supery));
			stalksradiushigh=length(dvec2(cx,cy))+stalksradius;
			stalksradiuslow=length(dvec2(cx,cy))-stalksradius;
			ztot=0.0;
			break;
	}
	trapped=false; //assume not trapped
}

void CheckOrbitTraps() {
	switch(orbitstyle) {
		case 1:
			//circle orbit trap
			trapdist=length(dvec2(z.y,z.x)-dvec2(trapx,trapy));
			if (trapdist<trapsize) { trapped=true; }
			epscolor=int(mod(iters,numpals));
			break;
		case 2:
			//cross orbit trap
			if (abs(z.x)<trapsize) {
				trapdist=abs(z.x);
				trapped=true;
			}
			if (abs(z.y)<trapsize) {
				trapdist=abs(z.y);
				trapped=true;
			}
			epscolor=int(mod(iters,numpals));
			break;
		case 3:
			//squares orbit trap
			if ((z.x>sxmin) && (z.x<sxmax) && (z.y>symin) && (z.y<symax)) {
				trapdist=min(min(z.x-sxmin,sxmax-z.x),min(z.y-symin,symax-z.y));
				trapped=true;
			}
			epscolor=int(mod(iters,numpals));
			break;
		case 4:
			//ring orbit trap
			//note:multiplying the first sqr(zr-trapy) by a
			//floating point number gives elipses
			trapdist=length(dvec2(z.y,z.x)-dvec2(trapx,trapy));
			if ((trapdist<trapmax) && (trapdist>trapmin)) { trapped=true; }
			epscolor=int(mod(iters,numpals));
			break;
		case 5:
			//stalks orbit trap
			if ((length(z)<=stalksradiushigh) && (length(z)>=stalksradiuslow) && (iters>1)) {
				ztot=sqrt(ztot)+(1-abs(length(z)-length(dvec2(cx,cy)))/stalksradius);
				trapped=true;
			}
			epscolor=int(mod(iters,numpals));
			break;
	}
}

void CalculateTrappedColor() {
	col=vec4(0.0,0.0,0.0,1.0);
	switch (orbitstyle) {
		case 1:
			//circle orbit trap
			distpercentage=min((1.0-trapdist/trapsize)*1.25,1.0); // *1.25 brightens the trap gradients
			switch (epscolor) {
				case 0:	col=vec4(distpercentage*trap1red,distpercentage*trap1green,distpercentage*trap1blue,1.0);	break;
				case 1:	col=vec4(distpercentage*trap2red,distpercentage*trap2green,distpercentage*trap2blue,1.0);	break;
				case 2:	col=vec4(distpercentage*trap3red,distpercentage*trap3green,distpercentage*trap3blue,1.0);	break;
				case 3:	col=vec4(distpercentage*trap4red,distpercentage*trap4green,distpercentage*trap4blue,1.0);	break;
				case 4:	col=vec4(distpercentage*trap5red,distpercentage*trap5green,distpercentage*trap5blue,1.0);	break;
			}
			break;
		case 2:
			//cross orbit trap
			distpercentage=min((1.0-trapdist/trapsize)*1.25,1.0); // *1.25 brightens the trap gradients
			switch (epscolor) {
				case 0:	col=vec4(distpercentage*trap1red,distpercentage*trap1green,distpercentage*trap1blue,1.0);	break;
				case 1:	col=vec4(distpercentage*trap2red,distpercentage*trap2green,distpercentage*trap2blue,1.0);	break;
				case 2:	col=vec4(distpercentage*trap3red,distpercentage*trap3green,distpercentage*trap3blue,1.0);	break;
				case 3:	col=vec4(distpercentage*trap4red,distpercentage*trap4green,distpercentage*trap4blue,1.0);	break;
				case 4:	col=vec4(distpercentage*trap5red,distpercentage*trap5green,distpercentage*trap5blue,1.0);	break;
			}
			break;
		case 3:
			//squares orbit trap
			distpercentage=min((trapdist/trapsize)*2.25,1.0); // *2.25 brightens the trap gradients
			switch (epscolor) {
				case 0:	col=vec4(distpercentage*trap1red,distpercentage*trap1green,distpercentage*trap1blue,1.0);	break;
				case 1:	col=vec4(distpercentage*trap2red,distpercentage*trap2green,distpercentage*trap2blue,1.0);	break;
				case 2:	col=vec4(distpercentage*trap3red,distpercentage*trap3green,distpercentage*trap3blue,1.0);	break;
				case 3:	col=vec4(distpercentage*trap4red,distpercentage*trap4green,distpercentage*trap4blue,1.0);	break;
				case 4:	col=vec4(distpercentage*trap5red,distpercentage*trap5green,distpercentage*trap5blue,1.0);	break;
			}
				break;
		case 4:
			//ring orbit trap
			distpercentage=(trapdist-trapmin)/(trapmax-trapmin);
			distpercentage=distpercentage*2.0;
			if (distpercentage>1) { distpercentage=distpercentage-1.0; distpercentage=1.0-distpercentage; }
			switch (epscolor) {
				case 0:	col=vec4(distpercentage*trap1red,distpercentage*trap1green,distpercentage*trap1blue,1.0);	break;
				case 1:	col=vec4(distpercentage*trap2red,distpercentage*trap2green,distpercentage*trap2blue,1.0);	break;
				case 2:	col=vec4(distpercentage*trap3red,distpercentage*trap3green,distpercentage*trap3blue,1.0);	break;
				case 3:	col=vec4(distpercentage*trap4red,distpercentage*trap4green,distpercentage*trap4blue,1.0);	break;
				case 4:	col=vec4(distpercentage*trap5red,distpercentage*trap5green,distpercentage*trap5blue,1.0);	break;
			}
			break;
		case 5:
			//stalks orbit trap
			distpercentage=min(sqrt(ztot)*1.25,1.0);  // *1.25 brightens the trap gradients
			switch (epscolor) {
				case 0:	col=vec4(distpercentage*trap1red,distpercentage*trap1green,distpercentage*trap1blue,1.0);	break;
				case 1:	col=vec4(distpercentage*trap2red,distpercentage*trap2green,distpercentage*trap2blue,1.0);	break;
				case 2:	col=vec4(distpercentage*trap3red,distpercentage*trap3green,distpercentage*trap3blue,1.0);	break;
				case 3:	col=vec4(distpercentage*trap4red,distpercentage*trap4green,distpercentage*trap4blue,1.0);	break;
				case 4:	col=vec4(distpercentage*trap5red,distpercentage*trap5green,distpercentage*trap5blue,1.0);	break;
			}
			break;
	}
}

//-----------------------------------------------------------------------------------------------
// roots
//-----------------------------------------------------------------------------------------------

void InitRoots() {
	//root colors for "single color per root" coloring
	rootcolors[0]=vec3(1.0,0.0,0.0); //red
	rootcolors[1]=vec3(0.0,0.5,0.0); //green
	rootcolors[2]=vec3(0.0,0.0,1.0); //blue
	rootcolors[3]=vec3(1.0,1.0,0.0); //yellow
	rootcolors[4]=vec3(1.0,0.0,1.0); //magenta
	rootcolors[5]=vec3(0.0,1.0,0.0); //lime
	rootcolors[6]=vec3(0.5,0.5,0.5); //gray
	rootcolors[7]=vec3(0.5,0.5,1.0); //aqua
	
	//root settings
	//
	// To find the roots, use WolframAlpha with "roots of z^4+3z^3+2z^2+0.2z+1"
	//
	switch (formula) {
		case 0:
			// z^3-1
			numroots=3;
			roots[0].x= 1.0;
			roots[0].y= 0.0;
			roots[1].x=-0.5;
			roots[1].y= 0.8660254037844386467637232;
			roots[2].x=-0.5;
			roots[2].y=-0.8660254037844386467637232;
			break;
		case 1:
			// z^4-1
			numroots=4;
			roots[0].x= 1.0;
			roots[0].y= 0.0;
			roots[1].x= 0.0;
			roots[1].y= 1.0;
			roots[2].x=-1.0;
			roots[2].y= 0.0;
			roots[3].x= 0.0;
			roots[3].y=-1.0;
			break;
		case 2:
			// z^5-1
			numroots=5;
			roots[0].x= 1.0;
			roots[0].y= 0.0;
			roots[1].x= 0.3090169943749474241022934;
			roots[1].y= 0.9510565162951535721164393;
			roots[2].x=-0.8090169943749474241022934;
			roots[2].y= 0.5877852522924731291687060;
			roots[3].x=-0.8090169943749474241022934;
			roots[3].y=-0.5877852522924731291687060;
			roots[4].x= 0.3090169943749474241022934;
			roots[4].y=-0.9510565162951535721164393;
			break;
		case 3:
			// z^6-1
			numroots=6;
			roots[0].x= 1.0;
			roots[0].y= 0.0;
			roots[1].x= 0.5;
			roots[1].y= 0.8660254037844386467637232;
			roots[2].x=-0.5;
			roots[2].y= 0.8660254037844386467637232;
			roots[3].x=-1.0;
			roots[3].y=-0.0;
			roots[4].x=-0.5;
			roots[4].y=-0.8660254037844386467637232;
			roots[5].x= 0.5;
			roots[5].y=-0.8660254037844386467637232;
			break;
		case 4:
			// z^4+z^3+z-1
			numroots=4;
			roots[0].x=-1.618033988749894848204587;
			roots[0].y= 0.0;
			roots[1].x= 0.0;
			roots[1].y=-1.0;
			roots[2].x= 0.0;
			roots[2].y= 1.0;
			roots[3].x= 0.618033988749894848204587;
			roots[3].y= 0.0;
			break;
		case 5:
			// z^4+z^3-1
			numroots=4;
			roots[0].x=-1.380277569097614115673302;
			roots[0].y= 0.0;
			roots[1].x=-0.2194474721492751620131347;
			roots[1].y=-0.9144736629677264559386162;
			roots[2].x=-0.2194474721492751620131347;
			roots[2].y= 0.9144736629677264559386162;
			roots[3].x= 0.8191725133961644396995712;
			roots[3].y= 0.0;
			break;
		case 6:
			// z^3+2z^2+z+3
			numroots=3;
			roots[0].x=-2.1745594102929800742023190;
			roots[0].y= 0.0;
			roots[1].x= 0.08727970514649003710115949;
			roots[1].y=-1.17131211100087873496374389;
			roots[2].x= 0.08727970514649003710115949;
			roots[2].y= 1.17131211100087873496374389;
			break;
		case 7:
			// z^4+3z^3+2z^2+0.2z+1
			numroots=4;
			roots[0].x=-1.675244752859875473894369;
			roots[0].y=-0.114950234113238614691684;
			roots[1].x=-1.675244752859875473894369;
			roots[1].y= 0.114950234113238614691684;
			roots[2].x= 0.1752447528598754738943694;
			roots[2].y=-0.5691591596968072351131500;
			roots[3].x= 0.1752447528598754738943694;
			roots[3].y= 0.5691591596968072351131500;
			break;
		case 8:
			// z^7-3z^5+6z^3-3z+3
			numroots=7;
			roots[0].x=-1.2088101115298400632848698;
			roots[0].y= 0.0;
			roots[1].x=-1.2264052130478101711367220;
			roots[1].y=-0.7744991389693667549994287;
			roots[2].x=-1.2264052130478101711367220;
			roots[2].y= 0.7744991389693667549994287;
			roots[3].x= 0.46340698650355286152546079;
			roots[3].y=-0.54837160412593303719457936;
			roots[4].x= 0.46340698650355286152546079;
			roots[4].y= 0.54837160412593303719457936;
			roots[5].x= 1.3674032823091773412536961;
			roots[5].y=-0.6470379653416892935760035;
			roots[6].x= 1.3674032823091773412536961;
			roots[6].y= 0.6470379653416892935760035;
			break;
		case 9:
			// z^5-5z^3+5z+3
			numroots=5;
			roots[0].x=-2.0371649068318159113;
			roots[0].y= 0.0;
			roots[1].x=-0.6295185765552875508;
			roots[1].y=-0.3683927668250164234;
			roots[2].x=-0.6295185765552875508;
			roots[2].y= 0.3683927668250164234;
			roots[3].x= 1.6481010299711955064;
			roots[3].y=-0.2276792511074748363;
			roots[4].x= 1.6481010299711955064;
			roots[4].y= 0.2276792511074748363;
			break;
		case 10:
			// z^8+15z^4-16
			numroots=8;
			roots[0].x=-1.414213562373095048801689;
			roots[0].y=-1.414213562373095048801689;
			roots[1].x=-1.414213562373095048801689;
			roots[1].y= 1.414213562373095048801689;
			roots[2].x=-1.0;
			roots[2].y= 0.0;
			roots[3].x= 0.0;
			roots[3].y=-1.0;
			roots[4].x= 0.0;
			roots[4].y= 1.0;
			roots[5].x= 1.0;
			roots[5].y= 0.0;
			roots[6].x= 1.414213562373095048801689;
			roots[6].y=-1.414213562373095048801689;
			roots[7].x= 1.414213562373095048801689;
			roots[7].y= 1.414213562373095048801689;
			break;
		case 11:
			// z^3-3z
			numroots=3;
			roots[0].x= 0.0;
			roots[0].y= 0.0;
			roots[1].x=-1.732050807568877293527446;
			roots[1].y= 0.0;
			roots[2].x= 1.732050807568877293527446;
			roots[2].y= 0.0;
			break;
		case 12:
			// z3-2z+2
			numroots=3;
			roots[0].x=-1.769292354238631415240409;
			roots[0].y= 0.0;
			roots[1].x= 0.8846461771193157076202047;
			roots[1].y=-0.5897428050222055016472807;
			roots[2].x= 0.8846461771193157076202047;
			roots[2].y= 0.5897428050222055016472807;
			break;
		case 13:
			// 2z^3-2z+2
			numroots=3;
			roots[0].x=-1.324717957244746025960909;
			roots[0].y= 0.0;
			roots[1].x= 0.6623589786223730129804544;
			roots[1].y=-0.5622795120623012438991821;
			roots[2].x= 0.6623589786223730129804544;
			roots[2].y= 0.5622795120623012438991821;
			break;
		case 14:
			// z^2(z^3-1)
			numroots=4;
			roots[0].x= 0.0;
			roots[0].y= 0.0;
			roots[1].x= 1.0;
			roots[1].y= 0.0;
			roots[2].x=-0.5;
			roots[2].y=-0.8660254037844386467637232;
			roots[3].x=-0.5;
			roots[3].y= 0.8660254037844386467637232;
			break;
		case 15:
			// z^3-z
			numroots=3;
			roots[0].x=-1;
			roots[0].y= 0.0;
			roots[1].x= 0.0;
			roots[1].y= 0.0;
			roots[2].x= 1.0;
			roots[2].y= 0.0;
			break;
		case 16:
			// (z^2-1)*(z^2-4)
			numroots=4;
			roots[0].x=-2.0;
			roots[0].y= 0.0;
			roots[1].x=-1.0;
			roots[1].y= 0.0;
			roots[2].x= 1.0;
			roots[2].y= 0.0;
			roots[3].x= 2.0;
			roots[3].y= 0.0;
			break;
		case 17:
			// z^4-5z^2+4
			numroots=4;
			roots[0].x= 2.0;
			roots[0].y= 0.0;
			roots[1].x= 1.0;
			roots[1].y= 0.0;
			roots[2].x=-1.0;
			roots[2].y= 0.0;
			roots[3].x=-2.0;
			roots[3].y= 0.0;
			break;
		case 18:
			// 8z^7-3z^4+5
			numroots=7;
			roots[0].x=-0.87798427114687700077914932;
			roots[0].y= 0.0;
			roots[1].x=-0.59598108930221005360274971;
			roots[1].y=-0.79446474316870102477101224;
			roots[2].x=-0.59598108930221005360274971;
			roots[2].y= 0.79446474316870102477101224;
			roots[3].x= 0.15659552835560800517200749;
			roots[3].y=-0.88310343030025561352239871;
			roots[4].x= 0.15659552835560800517200749;
			roots[4].y= 0.88310343030025561352239871;
			roots[5].x= 0.87837769652004054882031689;
			roots[5].y=-0.35446479302624861810754017;
			roots[6].x= 0.87837769652004054882031689;
			roots[6].y= 0.35446479302624861810754017;
	}
}

//-----------------------------------------------------------------------------------------------
// functions
//-----------------------------------------------------------------------------------------------

dvec2 func (dvec2 z) {
	dvec2 val;
	switch (formula) {
		case 0:
			// z^3-1
			val=(csub(cpow(z,3),c1));
			break;
		case 1:
			// z^4-1
			val=(csub(cpow(z,4),c1));
			break;
		case 2:
			// z^5-1
			val=(csub(cpow(z,5),c1));
			break;
		case 3:
			// z^6-1
			val=(csub(cpow(z,6),c1));
			break;
		case 4:
			// z^4+z^3+z-1
			val=(csub(cadd(cadd(cpow(z,4),cpow(z,3)),z),c1));
			break;
		case 5:
			// z^4+z^3-1
			val=(csub(cadd(cpow(z,4),cpow(z,3)),c1));
			break;
		case 6:
			// z^3+2z^2+z+3
			val=(cadd(cadd(cadd(cmul(cpow(z,2),c2),cpow(z,3)),z),c3));
			break;
		case 7:
			// z^4+3z^3+2z^2+0.2z+1
			val=(cadd(cadd(cadd(cadd(cpow(z,4),cmul(cpow(z,3),c3)),cmul(cpow(z,2),c2)),cmul(z,c0point2)),c1));
			break;
		case 8:
			// z^7-3z^5+6z^3-3z+3
			val=( cadd(cadd(cadd( cadd(cpow(z,7),cmul(-c3,cpow(z,5))) ,cmul(c6,cpow(z,3))),cmul(-c3,z)),c3) );
			break;
		case 9:
			// z^5-5z^3+5z+3
			val=(cadd(cadd(cadd(cpow(z,5),cmul(-c5,cpow(z,3))),cmul(c5,z)),c3));
			break;
		case 10:
			// z^8+15z^4-16
			val=( csub(cadd( cpow(z,8),cmul(c15,cpow(z,4)) ),c16)    );
			break;
		case 11:
			// z^3-3z
			val=( csub(cpow(z,3),cmul(c3,z)) );
			break;
		case 12:
			// z^3-2z+2
			val=( cadd(csub(cpow(z,3),cmul(c2,z)),c2) );
			break;
		case 13:
			//2z^3-2z+2
			val=( cadd(csub(cmul(c2,cpow(z,3)),cmul(c2,z)),c2) );
			break;
		case 14:
			//z^2(z^3-1)
			val=( cmul(cpow(z,2),csub(cpow(z,3),c1)) );
			break;
		case 15:
			//z^3-z
			val=( csub(cpow(z,3),z) );
			break;
		case 16:
			//(z^2-1)*(z^2-4)
			val=( cmul( csub(cpow(z,2),c1) , csub(cpow(z,2),c4) ) );
			break;
		case 17:
			// z^4-5z^2+4
			val=(cadd(csub(cpow(z,4),cmul(c5,cpow(z,2))),c4));
			break;
		case 18:
			// 8z^7-3z^4+5
			val=( cadd(csub(cmul(c8,cpow(z,7)),cmul(c3,cpow(z,4)) ),c5 ));
			break;
	}
	return val;
}

//-----------------------------------------------------------------------------------------------
// 1st derivatives
//-----------------------------------------------------------------------------------------------

dvec2 deriv (dvec2 z) {
	//
	// To find the first derivatives, use WolframAlpha with "D[z^4+3z^3+2z^2+0.2z+1,z]"
	//
	dvec2 val;
	switch (formula) {
		case 0:
			// z^3-1 derivative 3z^2
			val=(cmul(cpow(z,2),c3));
			break;
		case 1:
			// z^4-1 derivative 4z^3
			val=(cmul(cpow(z,3),c4));
			break;
		case 2:
			// z^5-1 derivative 5z^4
			val=(cmul(cpow(z,4),c5));
			break;
		case 3:
			// z^6-1 derivative 6z^5
			val=(cmul(cpow(z,5),c6));
			break;
		case 4:
			// z^4+z^3+z-1 derivative 1+3z^2+4z^3
			val=(cadd(c1,cadd(cmul(cpow(z,2),c3),cmul(cpow(z,3),c4))));
			break;
		case 5:
			// z^4+z^3-1 derivative 3z^2+4z^3
			val=(cadd(cmul(cpow(z,2),c3),cmul(cpow(z,3),c4)));
			break;
		case 6:
			// z^3+2z^2+z+3 derivative 1+4z+3z^2
			val=(cadd(cadd(cmul(z,c4),cmul(cpow(z,2),c3)),c1));
			break;
		case 7:
			// z^4+3z^3+2z^2+0.2z+1 derivative 0.2+4z+9z^2+4z^3
			val=(cadd(cadd(cadd(c0point2,cmul(z,c4)),cmul(cpow(z,2),c9)),cmul(cpow(z,3),c4)));
			break;
		case 8:
			// z^7-3z^5+6z^3-3z+3 derivative -3+18z^2-15z^4+7z^6
			val=(  cadd(cadd(cadd(cmul(c7,cpow(z,6)),cmul(-c15,cpow(z,4))),cmul(c18,cpow(z,2))),-c3) );
			break;
		case 9:
			// z^5-5z^3+5z+3 derivative 5-15z^2+5z^4
			val=( cadd(cadd(cmul(c5,cpow(z,4)),cmul(-c15,cpow(z,2))),c5) );
			break;
		case 10:
			// z^8+15z^4-16 derivative 60z^3+8z^7
			val=( cadd(cmul(c60,cpow(z,3)),cmul(c8,cpow(z,7))));
			break;
		case 11:
			// z3-3z derivative 3(z^2-1)
			val=( cmul(c3,csub(cpow(z,2),c1)) );
			break;
		case 12:
			// z^3-2z+2 derivative 3z^2-2
			val=( csub(cmul(c3,cpow(z,2)),c2) );
			break;
		case 13:
			//2z^3-2z+2=0 derivative 6z^2-2
			val=( csub(cmul(c6,cpow(z,2)),c2) );
			break;
		case 14:
			//z^2(z^3-1) derivative 5z^4-2z
			val=( csub(cmul(c5,cpow(z,4)) ,cmul(c2,z)) );
			break;
		case 15:
			//z^3-z derivative 3z^2-1
			val=( csub(cmul(c3,cpow(z,2)),c1) );
			break;
		case 16:
			//(z^2-1)*(z^2-4) derivative 4z^3-10z
			val=( csub( cmul(c4,cpow(z,3)) , cmul(c10,z) ) );
			break;
		case 17:
			// z^4-5z^2+4 derivative 4z^3-10z
			val=(csub(cmul(c4,cpow(z,3)),cmul(c10,z)));
			break;
		case 18:
			// 8z^7-3z^4+5 derivative  4z^3(14z^3-3)
			val=(cmul(cmul(c4,cpow(z,3)) ,csub(cmul(c14,cpow(z,3)),c3) ));
			break;
	}
	return val;
}	

//-----------------------------------------------------------------------------------------------
// 2nd derivatives
//-----------------------------------------------------------------------------------------------

dvec2 deriv2 (dvec2 z) {
	//
	// To find the second derivatives, use WolframAlpha with "D[z^4+3z^3+2z^2+0.2z+1,{z,2}]"
	//
	dvec2 val;
	switch (formula) {
		case 0:
			// z^3-1 2nd derivative 6z
			val=(cmul(z,c6));
			break;
		case 1:
			// z^4-1 2nd derivative 12z^2
			val=(cmul(cpow(z,2),c12));
			break;
		case 2:
			// z^5-1 2nd derivative 20z^3
			val=(cmul(cpow(z,3),c20));
			break;
		case 3:
			// z^6-1 2nd derivative 30z^4
			val=(cmul(cpow(z,4),c30));
			break;
		case 4:
			// z^4+z^3+z-1 2nd derivative 6z(2z+1)
			val=(cmul(cmul(c6,z),cadd(cmul(c2,z),c1)));
			break;
		case 5:
			// z^4+z^3+z 2nd derivative 6z(2z+1)
			val=(cmul(cmul(c6,z),cadd(cmul(c2,z),c1)));
			break;
		case 6:
			// z^3+2z^2+z+3 2nd derivative 6z+4
			val=(cadd(cmul(z,c6),c4));
			break;
		case 7:
			// z^4+3z^3+2z^2+0.2z+1 2nd derivative 2(6z^2+9z+2)
			val=(cmul(cadd(cadd(cmul(cpow(z,2),c6),cmul(z,c9)),c2),c2));
			break;
		case 8:
			// z^7-3z^5+6z^3-3z+3 2nd derivative 6z(7z^4-10z^2+6)
			val=( cadd(cadd(cmul(c42,cpow(z,5)) , cmul(-c60,cpow(z,3))) , cmul(c36,z)) );
			break;
		case 9:
			// z^5-5z^3+5z+3 2nd derivative 10z(2z^2-3)
			val=(cadd(cmul(c20,cpow(z,3)),cmul(-c30,z)));
			break;
		case 10:
			// z^8+15z^4-16 2nd derivative 4z^2(14z^4+45)
			val=( cmul( cmul(c4,cpow(z,2)),cadd(cmul(c14,cpow(z,4)),c45)) );
			break;
		case 11:
			// z3-3z 2nd derivative 6z
			val=( cmul(z,c6) );
			break;
		case 12:
			// z^3-2z+2 2nd derivative 6z
			val=( cmul(c6,z) );
			break;
		case 13:
			//2z^3-2z+2=0 2nd derivative 12z
			val=( cmul(c12,z) );
			break;
		case 14:
			//z^2(z^3-1) 2nd derivative 20z^3-2
			val=( csub(cmul(c20,cpow(z,3)) ,c2));
			break;
		case 15:
			//z^3-z 2nd derivative 6z
			val=( cmul(c6,z) );
			break;
		case 16:
			//(z^2-1)*(z^2-4) 2nd derivative 12z^2-10
			val=( csub(cmul(c12,cpow(z,2)),c10) );
			break;
		case 17:
			// z^4-5z^2+4 2nd derivative 12z^2-10
			val=(csub(cmul(c12,cpow(z,2)),c10));
			break;
		case 18:
			// 8z^7-3z^4+5 2nd derivative 12z^2(28z^3-3)
			val=(cmul(cmul(c12,cpow(z,2)) ,csub(cmul(c28,cpow(z,3)),c3) ));
			break;
	}
	return val;
}	

//-----------------------------------------------------------------------------------------------
// main function
//-----------------------------------------------------------------------------------------------

void main(void)
{
	finalcol=vec4(0,0,0,0);
	int count,sn;

	InitRoots();
	
	for (supery=0;supery<samplepixels;supery++)
	{
		for (superx=0;superx<samplepixels;superx++)
		{
	
			if (orbitstyle>0) { InitOrbitTraps(); }

			z.x = xmin+gl_FragCoord.x/resolution.x*(xmax-xmin)+(stepx*double(superx));
			z.y = ymin+gl_FragCoord.y/resolution.y*(ymax-ymin)+(stepy*double(supery));
			
			//BUG FIX?
			//These shaders can totally lock up the PC when rendering pixels near the X axis at 0.
			//The following two ifs are trying to "bump" that 0 not so close to 0.
			if ((z.x>-0.000000000001) && (z.x<0.000000000001)) { z.x=0.000000000001; }
			if ((z.y>-0.000000000001) && (z.y<0.000000000001)) { z.y=0.000000000001; }
			
			lastz=z;
			lastz2=z;
			count=0;
			if (method==9) {  //for SECANT METHOD only
				w.x=sec.x;
				w.y=sec.y;
			}

			int i;
			for(i=0; i<maxiters; i++) 
			{
				f=func(z);
				d=deriv(z);
				d2=deriv2(z);
				//------------------------------------------------------------------------------------------------
				if (method>=9) {                                 //2-step method selected? 
					if (method!=9) {                              //skip Newton step for SECANT METHOD (method=10)
						if (method<21) {							//less thasn "Sharma" in method list
							w=csub(z,cdiv(f,d));                    //perform 1st Step (Newton) for 2-step method
						}
						else {
							w= csub(z,cmul(cdiv(c2,c3),cdiv(f,d))); //perform 1st step (modified Newton) (method>=30)
						}
					}
					fw=func(w);
					dw=deriv(w);
					d2w=deriv2(w);
				}
				//------------------------------------------------------------------------------------------------
				switch (method) {
    				case 0:
				      	//NEWTON Method
				      z=csub(z,cmul(a,cdiv(f,d)));
			      		break;
    			   case 1:
				      //HALLEY Method
					   z=csub(z,cmul(a,cdiv(cmul(c2,cmul(f,d)),csub(cmul(c2,cmul(d,d)),cmul(f,d2)))));
			      		break;
    			   case 2:
				      //SCHRÖDER Method
					   z=csub(z,cmul(a,cdiv(cmul(f,d),csub(cmul(d,d),cmul(f,d2)))));
			      		break;
    			   case 3:
				      //HOUSEHOLDER Method
                   z=csub(z,cmul(cmul(cdiv(f,d),cadd(c1,cdiv(cmul(f,d2),cmul(c2,cmul(d,d))))),a));
			      		break;
    			   case 4:
				      //BASTO Method
						z=csub(csub(z,cdiv(f,d)),cdiv(cmul(cmul(f,f),d2),csub(cmul(c2,cmul(f,cmul(f,f))),cmul(c2,cmul(f,cmul(d,d2))))));
			      		break;
    			   case 5:
						//WHITTAKER I Method
						L=csub(c2,cdiv(cmul(d2,f),cmul(d,d)));
						z=csub(z,cmul(cdiv(f,cmul(c2,d)),L));
			      		break;
    			   case 6:
						//WHITTAKER II Method
						L=csub(c2,cdiv(cmul(d2,f),cmul(d,d)));
						z=csub(z,cmul(cdiv(f,cmul(c4,d)),cadd(csub(c2,L),cdiv(cadd(c4,cmul(c2,L)),csub(c2,cmul(L,csub(c2,L)))))));
			      		break;
    			   case 7:
						//EULER-CHEBYSHEV Method
						z=csub(csub(z,cmul(cdiv(cmul(m,csub(c3,m)),c2),cdiv(f,d))),cmul(cdiv(cmul(m,m),c2),cdiv(cmul(cmul(f,f),d2),cmul(cmul(d,d),d) )));
			      		break;
    			   case 8:
						//CHUN-KIM I Method
						z=csub(z,cmul(a,cdiv(cadd(cmul(cmul(f,f),d),cmul(cmul(c2,f),cmul(d,d))), cmul(c2,cmul(d,cmul(d,d))) )));
			      		break;
    			   case 9:
						//SECANT Method
						z=csub(z,cmul(cdiv(csub(z,w),csub(f,fw)),f));
			      		break;
    			   case 10:
				      //OSTROWSKI Method
						z=csub(z,cmul(cdiv(f,d),cdiv(csub(f,fw),csub(f,cmul(c2,fw) ) )));
			      		break;
    			   case 11:
				      //KING Method
						z=csub(w,cmul(cdiv(fw,d),cdiv(cadd(f,cmul(beta,fw)),cadd(f,cmul(csub(beta,c2),fw)))));
			      		break;
    			   case 12:
				      //CHUN II Method
						z=csub(csub(z,cdiv(f,d)),cdiv(cmul(c2,fw),cadd(d,dw)));
			      		break;
    			   case 13:
				      //CHUN III Method
						//z=csub(csub(z,cdiv(f,d)),cdiv(cmul(f,fw),cmul(csub(f,fw),d))); //CHUN ezzatiIMF25-28-2011.pdf
						z=csub(csub(z,cdiv(f,d)),cdiv(cmul(f,fw),cmul(csub(f,fw),d)));
			      		break;
    			   case 14:
				      //FENG Method
						z=csub(w,cmul(a,cdiv(fw,csub(cmul(c2,d),dw))));
			      		break;
    			   case 15:
				      //CONTRA HARMONIC NEWTON Method
						z=csub(z,cmul(a,  cdiv( cmul(f,cadd(d,dw))  ,  cadd(cmul(d,d),cmul(dw,dw)) )   ));
			      		break;
    			   case 16:
				      //KUNG-TRAUB Method
						z=csub(w,cmul(cdiv(fw,d),cmul(csub(c1,cdiv(fw,f)),csub(c1,cdiv(fw,f)))));
			      		break;
    			   case 17:
				      //FANG Method
						z=csub(z,cmul(cdiv(csub(cmul(c3,d),dw),cadd(d,dw)),cdiv(f,d)));
			      		break;
    			   case 18:
				      //RAFIQ Method
						//zähler=cmul(cmul(f,f),d2w)
						//nenner=csub(cmul(cmul(d,d),d),cmul(cmul(f,d),d2)
						z=csub(csub(z,cdiv(f,d)), cmul(cdiv(c1,c2),cdiv(cmul(cmul(f,f),d2w),csub(cmul(cmul(d,d),d),cmul(cmul(f,d),d2)))));
			      		break;
    			   case 19:
				      //CHUN-KIM II Method
						term1=cmul(f,csub(cadd(c2,cmul(c3,cmul(d,d))),cmul(d,dw)));						
						term2=cadd(cadd(d,cmul(c2,cmul(cmul(d,d),d))),dw);
						z=csub(z,cdiv(term1,term2));
			      		break;
    			   case 20:
				      //CHUN-KIM III Method
						z=csub(z,cmul(cmul(cdiv(c1,c2),csub(c3,cdiv(dw,d))),cdiv(f,d)) );
			      		break;
    			   case 21:
				      //SHARMA Method
						z=csub(z,cmul(cadd(cadd(cdiv(-c1,c2),cmul(cdiv(c9,c8),cdiv(d,dw))),cmul(cdiv(c3,c8),cdiv(dw,d))),cdiv(f,d)));
			      		break;
    			   case 22:
				      //CHUN LEE Method
						z=cadd(z,cdiv(cmul(c16,cmul(f,d)), cadd(csub(cmul(c5,cmul(d,d)),cmul(c30,cmul(d,dw))),cmul(c9,cmul(dw,dw)))  ));
			      		break;
				}

				if (distance(z,lastz)<tolerance) {
					break;
				} else {
					if (method==9) {
						w=lastz;
					}	
					lastz2=lastz;
					lastz=z;
					count++;
				}
				
				iters=count;
				CheckOrbitTraps();
				if (trapped==true) { break; }
			}
			
			//Convergence Check
			int hitroot=-1;
			for(i=0; i<numroots; i++) 
			{
				if (distance(z,roots[i])<tolerance) {
					hitroot=i;
				}
			}
				
			if (orbitstyle>0) {
				if ((trapped==true)||(onlyshowtraps==true)) {
					if (trapped==false) {
					col=vec4(0.0,0.0,0.0,1.0);
					} else {
						CalculateTrappedColor();
						}
					} else {
						if (hitroot==-1) { col=vec4(0.0,0.0,0.0,1.0); //divergence: color=black
						} else {
							switch (color_scheme) {
								case 0: //SINGLE COLOR PER ROOT
								col=vec4(rootcolors[hitroot],1.0);
								break;
								case 1: //SHADED COLOR
								colval=int(mod(count*palettestep,256));
								r1=palette[colval].r;
								g1=palette[colval].g;
								b1=palette[colval].b;
								col=vec4(r1,g1,b1,1.0);
								break;
								case 2: //SMOOTH COLOR
								dist0=distance(lastz2,lastz);
								dist1=distance(lastz,z);
								logt=log(float(tolerance));
								log0=log(float(dist0));
								log1=log(float(dist1));
								floatval=(logt-log0)/(log1-log0);
								colval=int(mod(count*palettestep,256));
								colval1=int(mod((count*palettestep)+palettestep,256));
								r1=palette[colval].r;
								g1=palette[colval].g;
								b1=palette[colval].b;
								r2=palette[colval1].r;
								g2=palette[colval1].g;
								b2=palette[colval1].b;
								r3=(r1+(r2-r1)*floatval);
								g3=(g1+(g2-g1)*floatval);
								b3=(b1+(b2-b1)*floatval);
								col=vec4(r3,g3,b3,1.0);
								break;
							}
						}
					}
				
			} else {
				if (hitroot==-1) { col=vec4(0.0,0.0,0.0,1.0); //divergence: color=black
				} else {
					switch (color_scheme) {
						case 0: //SINGLE COLOR PER ROOT
							col=vec4(rootcolors[hitroot],1.0);
							break;
						case 1: //SHADED COLOR
							colval=int(mod(count*palettestep,256));
							r1=palette[colval].r;
							g1=palette[colval].g;
							b1=palette[colval].b;
							col=vec4(r1,g1,b1,1.0);
							break;
						case 2: //SMOOTH COLOR
							dist0=distance(lastz2,lastz);
							dist1=distance(lastz,z);
							logt=log(float(tolerance));
							log0=log(float(dist0));
							log1=log(float(dist1));
							floatval=(logt-log0)/(log1-log0);
							colval=int(mod(count*palettestep,256));
							colval1=int(mod((count*palettestep)+palettestep,256));
							r1=palette[colval].r;
							g1=palette[colval].g;
							b1=palette[colval].b;
							r2=palette[colval1].r;
							g2=palette[colval1].g;
							b2=palette[colval1].b;
							r3=(r1+(r2-r1)*floatval);
							g3=(g1+(g2-g1)*floatval);
							b3=(b1+(b2-b1)*floatval);
							col=vec4(r3,g3,b3,1.0);
							break;
					}
				}
			}			
			finalcol+=col;
		}
	}
	glFragColor = vec4(finalcol/double(sqrsamplepixels));
}	
