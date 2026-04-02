#version 420

// plotting the result of a double pendulum simulation across a 2D image
// https://softologyblog.wordpress.com/2015/07/03/pendulum-plots/

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

//set the pendulum you want to plot to true
const bool doublependulum=true;
const bool triplependulum=false;
const bool quadruplependulum=false;

//simulation parameters
const float p4mass=1.0;
const float p3mass=1.0;
const float p2mass=1.0;
const float p1mass=1.0;
const float p4lpercent=30.0;
const float p3lpercent=30.0;
const float p2lpercent=24.0;
const float p1lpercent=24.0;
const float p4angle=177.0;
const float p3angle=178.0;
const float p2angle=179.0;
const float p1angle=180.0;
int iters=int(time*500.0);
const float dt=0.0005;
const float grav=9.81;
const float ymax=360.0;
const float ymin=0.0;
const float xmax=360.0;
const float xmin=0.0;
const float friction=0.0;

int iw=int(resolution.x);
int ih=int(resolution.y);
int iwdiv2=int(iw/2);
int ihdiv2=int(ih/2);

//supersampling amount
const int samplepixels=1;

float sqrsamplepixels=float(samplepixels*samplepixels);
float magnitude,realiters,r1,r2,g1,g2,b1,b2,tweenval;
vec4 finalcol,col;
int superx,supery,loop;
float dx=(xmax-xmin)/resolution.x/float(samplepixels);
float dy=(ymax-ymin)/resolution.y/float(samplepixels);
int index,colval,colval2;
float xp,yp;
vec2 z,c;
float phi1,phi2,phi3,phi4,m1,m2,m3,m4,p1l,p2l,p3l,p4l,omega1,omega2,omega3,omega4,px1,py1,px2,py2,px3,py3,px4,py4;
float pi=3.14159265;
float k10,k11,k12,k13,l10,l11,l12,l13;
float k20,k21,k22,k23,l20,l21,l22,l23;
float k30,k31,k32,k33,l30,l31,l32,l33;
float k40,k41,k42,k43,l40,l41,l42,l43;

//force on Phi_1
float DPforcephi1(in float phi1,in float phi2,in float omega1,in float omega2) {
     return -(grav*(2.0*m1*sin(phi1)+m2*sin(phi1)+m2*sin(phi1-2.0*phi2))
                +m2*omega1*omega1*sin(2.0*phi1-2.0*phi2)+2.0*m2*omega2*omega2*sin(phi1-phi2))
                /(2.0*m1+m2-m2*cos(2.0*phi1-2.0*phi2))-0.1*friction*omega1;
}
//force on Phi_2
float DPforcephi2(in float phi1,in float phi2,in float omega1,in float omega2) {
     return (2.0*sin(phi1-phi2)*(grav*(m1+m2)*cos(phi1)+(m1+m2)*omega1*omega1+m2*omega2*omega2*cos(phi1-phi2)))
                /(2.0*m1+m2-m2*cos(2.0*phi1-2.0*phi2))-0.1*friction*omega2;
}

//force on Phi_1
float TPforcephi1(in float phi1,in float omega1,in float phi2,in float omega2,in float phi3,in float omega3) {
     return (10.0*grav*sin(phi1)+4.0*grav*sin(phi1-2.0*phi2)-grav*sin(phi1+2.0*phi2-2.0*phi3)
                  -grav*sin(phi1-2.0*phi2+2.0*phi3)+4.0*omega1*omega1*sin(2.0*phi1-2.0*phi2)
                  +8.0*omega2*omega2*sin(phi1-phi2)+2.0*omega3*omega3*sin(phi1-phi3)
                  +2.0*omega3*omega3*sin(phi1-2.0*phi2+phi3))
                  /(-10.0+4.0*cos(2.0*phi1-2.0*phi2)+2.0*cos(2.0*phi2-2.0*phi3))-0.1*friction*omega1;
}

//force on Phi_2
float TPforcephi2(in float phi1,in float omega1,in float phi2,in float omega2,in float phi3,in float omega3) {
     return (-7.0*grav*sin(2.0*phi1-phi2)+7.0*grav*sin(phi2)+grav*sin(phi2-2.0*phi3)
                  +grav*sin(2.0*phi1+phi2-2.0*phi3)+2.0*omega1*omega1*sin(phi1+phi2-2.0*phi3)
                  -14.0*omega1*omega1*sin(phi1-phi2)+2.0*omega2*omega2*sin(2.0*phi2-2.0*phi3)
                  -4.0*omega2*omega2*sin(2.0*phi1-2.0*phi2)+6.0*omega3*omega3*sin(phi2-phi3)
                  -2.0*omega3*omega3*sin(2.0*phi1-phi2-phi3))
                  /(-10.0+4.0*cos(2.0*phi1-2.0*phi2)+2.0*cos(2.0*phi2-2.0*phi3))-0.1*friction*omega2;
}

//force on Phi_3
float TPforcephi3(in float phi1,in float omega1,in float phi2,in float omega2,in float phi3,in float omega3) {
     return -2.0*sin(phi2-phi3)*(grav*cos(2.0*phi1-phi2)+grav*cos(phi2)
                  +2.0*omega1*omega1*cos(phi1-phi2)+2.0*omega2*omega2+omega3*omega3*cos(phi2-phi3))
                  /(-5.0+2.0*cos(2.0*phi1-2.0*phi2)+cos(2.0*phi2-2.0*phi3))-0.1*friction*omega3;
}

//force on Phi_1
float QPforcephi1(in float phi1,in float omega1,in float phi2,in float omega2,in float phi3,in float omega3,in float phi4,in float omega4) {
     return (3.0*(493.0*grav*sin(phi1)-2.0*omega2*omega2*(-187.0+45.0*cos(2.0*(phi3-phi4)))
                  *sin(phi1-phi2)+3.0*omega2*omega2*(-9.0*sin(phi1+phi2-2.0*phi3)+sin(phi1+phi2-2.0*phi4))
                  +3.0*omega1*omega1*((73.0-18.0*cos(2.0*(phi3-phi4)))*sin(2.0*(phi1-phi2))
                  -9.0*sin(2.0*(phi1-phi3))+sin(2.0*(phi1-phi4)))+omega4*omega4*(sin(phi1-phi4)
                  +27.0*sin(phi1-2.0*phi2+2.0*phi3-phi4)+6.0*sin(phi1-2.0*phi2+phi4)+18.0*sin(phi1-2.0*phi3+phi4))
                  +3.0*omega3*omega3*(21.0*sin(phi1-phi3)+36.0*sin(phi1-2.0*phi2+phi3)-2.0*sin(phi1+phi3-2.0*phi4)
                  -3.0*sin(phi1-2.0*phi2-phi3+2.0*phi4))+3.0*grav*(73.0*sin(phi1-2.0*phi2)-9.0*sin(phi1-2.0*phi3)
                  -27.0*sin(phi1+2.0*phi2-2.0*phi3)-27.0*sin(phi1-2.0*phi2+2.0*phi3)-9.0*sin(phi1-2.0*(phi2+phi3-phi4))
                  +sin(phi1-2.0*phi4)+3.0*(sin(phi1+2.0*phi2-2.0*phi4)-7.0*sin(phi1+2.0*phi3-2.0*phi4)
                  +sin(phi1-2.0*phi2+2.0*phi4)-7.0*sin(phi1-2.0*phi3+2.0*phi4)-3.0*sin(phi1-2.0*(phi2-phi3+phi4))))))
                  /(-1310.0+657.0*cos(2.0*(phi1-phi2))-81.0*cos(2.0*(phi1-phi3))+405.0*cos(2.0*(phi2-phi3))
                  +9.0*cos(2.0*(phi1-phi4))-45.0*cos(2.0*(phi2-phi4))+333.0*cos(2.0*(phi3-phi4))
                  -81.0*cos(2.0*(phi1-phi2+phi3-phi4))-81.0*cos(2.0*(phi1-phi2-phi3+phi4)))-0.1*friction*omega1;
}

//force on Phi_2
float QPforcephi2(in float phi1,in float omega1,in float phi2,in float omega2,in float phi3,in float omega3,in float phi4,in float omega4) {
     return (-3.0*(758.0*omega1*omega1*sin(phi1-phi2)-18.0*cos(2.0*(phi3-phi4))*(11.0*omega1*omega1*sin(phi1-phi2)
                  +3.0*omega2*omega2*sin(2.0*(phi1-phi2))+6.0*grav*sin(2.0*phi1-phi2)-5.0*grav*sin(phi2))
                  +15.0*omega1*omega1*(-9.0*sin(phi1+phi2-2.0*phi3)+sin(phi1+phi2-2.0*phi4))+grav*(411.0*sin(2.0*phi1-phi2)
                  -347.0*sin(phi2)-54.0*sin(phi2-2.0*phi3)-81.0*sin(2.0*phi1+phi2-2.0*phi3)+6.0*sin(phi2-2.0*phi4)
                  +9.0*sin(2.0*phi1+phi2-2.0*phi4))+3.0*omega3*omega3*(36.0*sin(2.0*phi1-phi2-phi3)
                  -3.0*(37.0*sin(phi2-phi3)+sin(2.0*phi1-phi2+phi3-2.0*phi4))+8.0*sin(phi2+phi3-2.0*phi4))
                  +3.0*omega2*omega2*(73.0*sin(2.0*(phi1-phi2))+5.0*(-9.0*sin(2.0*(phi2-phi3))+sin(2.0*(phi2-phi4))))
                  +omega4*omega4*(6.0*sin(2.0*phi1-phi2-phi4)-31.0*sin(phi2-phi4)+27.0*sin(2.0*phi1-phi2-2.0*phi3+phi4)
                  -72.0*sin(phi2-2.0*phi3+phi4))))/(-1310.0+657.0*cos(2.0*(phi1-phi2))-81.0*cos(2.0*(phi1-phi3))+405.0*cos(2.0*(phi2-phi3))
                  +9.0*cos(2.0*(phi1-phi4))-45.0*cos(2.0*(phi2-phi4))+333.0*cos(2.0*(phi3-phi4))-81.0*cos(2.0*(phi1-phi2+phi3-phi4))
                  -81.0*cos(2.0*(phi1-phi2-phi3+phi4)))-0.1*friction*omega2;
}

//force on Phi_3
float QPforcephi3(in float phi1,in float omega1,in float phi2,in float omega2,in float phi3,in float omega3,in float phi4,in float omega4) {
     return (3.0*(3.0*omega2*omega2*(18.0*sin(2.0*phi1-phi2-phi3)-3.0*(49.0*sin(phi2-phi3)
                  +sin(2.0*phi1-phi2+phi3-2.0*phi4))+22.0*sin(phi2+phi3-2.0*phi4))+omega4*omega4*(9.0*sin(2.0*phi1-phi3-phi4)
                  -45.0*sin(2.0*phi2-phi3-phi4)+14.0*(+17.0-9.0*cos(2.0*(phi1-phi2)))*sin(phi3-phi4))+3.0*omega3*omega3*(9.0*sin(2.0*(phi1-phi3))
                  -45.0*sin(2.0*(phi2-phi3))+(+37.0-18.0*cos(2.0*(phi1-phi2)))*sin(2.0*(phi3-phi4)))+3.0*omega1*omega1*(-39.0*sin(phi1-phi3)
                  +90.0*sin(phi1-2.0*phi2+phi3)+4.0*sin(phi1+phi3-2.0*phi4)-15.0*sin(phi1-2.0*phi2-phi3+2.0*phi4))+3.0*grav*(-27.0*sin(2.0*phi1-phi3)-36.0*sin(2.0*phi2-phi3)
                  +12.0*sin(phi3)+54.0*sin(2.0*phi1-2.0*phi2+phi3)+sin(phi3-2.0*phi4)+3.0*sin(2.0*phi1+phi3-2.0*phi4)+6.0*sin(2.0*phi2+phi3-2.0*phi4)
                  -9.0*sin(2.0*phi1-2.0*phi2-phi3+2.0*phi4))))/(-1310.0+657.0*cos(2.0*(phi1-phi2))-81.0*cos(2.0*(phi1-phi3))+405.0*cos(2.0*(phi2-phi3))
                  +9.0*cos(2.0*(phi1-phi4))-45.0*cos(2.0*(phi2-phi4))+333.0*cos(2.0*(phi3-phi4))-81.0*cos(2.0*(phi1-phi2+phi3-phi4))
                  -81.0*cos(2.0*(phi1-phi2-phi3+phi4)))-0.1*friction*omega3;
}

//force on Phi_4
float QPforcephi4(in float phi1,in float omega1,in float phi2,in float omega2,in float phi3,in float omega3,in float phi4,in float omega4) {
     return (-3.0*(omega3*omega3*(9.0*sin(2.0*phi1-phi3-phi4)-45.0*sin(2.0*phi2-phi3-phi4)+2.0*(+251.0-117.0*cos(2.0*(phi1-phi2)))*sin(phi3-phi4))
                  +3.0*omega4*omega4*(sin(2.0*(phi1-phi4))-5.0*sin(2.0*(phi2-phi4))+(37.-18.0*cos(2.0*(phi1-phi2)))*sin(2.0*(phi3-phi4)))
                  +omega1*omega1*(sin(phi1-phi4)+135.0*sin(phi1-2.0*phi2+2.0*phi3-phi4)-60.0*sin(phi1-2.0*phi2+phi4)-36.0*sin(phi1-2.0*phi3+phi4))
                  +omega2*omega2*(-12.0*sin(2.0*phi1-phi2-phi4)+73.0*sin(phi2-phi4)+27.0*sin(2.0*phi1-phi2-2.0*phi3+phi4)-198.0*sin(phi2-2.0*phi3+phi4))+grav*(3.0*sin(2.0*phi1-phi4)
                  +24.0*sin(2.0*phi2-phi4)+9.0*sin(2.0*phi3-phi4)+81.0*sin(2.0*(phi1-phi2+phi3)-phi4)+2.0*sin(phi4)-9.0*(4.0*sin(2.0*phi1-2.0*phi2+phi4)+3.0*sin(2.0*phi1-2.0*phi3+phi4)
                  +6.0*sin(2.0*phi2-2.0*phi3+phi4)))))/(-1310.0+657.0*cos(2.0*(phi1-phi2))-81.0*cos(2.0*(phi1-phi3))+405.0*cos(2.0*(phi2-phi3))+9.0*cos(2.0*(phi1-phi4))-45.0*cos(2.0*(phi2-phi4))
                  +333.0*cos(2.0*(phi3-phi4))-81.0*cos(2.0*(phi1-phi2+phi3-phi4))-81.0*cos(2.0*(phi1-phi2-phi3+phi4)))-0.1*friction*omega4;
}

void main(void)
{
    px2=0.0;
    py2=0.0;
    finalcol=vec4(0,0,0,0);
    for (int supery=0;supery<samplepixels;supery++)
    {
        for (int superx=0;superx<samplepixels;superx++)
        {
            xp = xmin+gl_FragCoord.x/resolution.x*(xmax-xmin)+(dx*float(superx));
            // ymax- flips y coordinates as Visions Of Chaos uses top left origin for coordinates
            yp = ymax-gl_FragCoord.y/resolution.y*(ymax-ymin)+(dy*float(supery));

            
            //////////////////////////////////////////////////////////////////////////////////////////////////
            // Double Pendulum
            //////////////////////////////////////////////////////////////////////////////////////////////////
            
            if (doublependulum==true) {
            
            //initial values
            //the angles are being changed per pixel
            phi1=pi/180.0*xp; //p1 angle
            phi2=pi/180.0*yp; //p2 angle
            m1=p1mass; //p1 mass
            m2=p2mass; //p2 mass
            p1l=p1lpercent/100.0*float(ih); //p1 length %
            p2l=p2lpercent/100.0*float(ih); //p2 length %
            omega1=0.0;
            omega2=0.0;

            //iterate it - 10000 is the maximum animated time it loops to
            //for (int loop=0;loop<10000;loop++)
            for (int loop=0;loop<4096;loop++)
            {
                //runge kutta phi1
                k10=dt*omega1;
                l10=dt*DPforcephi1(phi1,phi2,omega1,omega2);
                k11=dt*(omega1+l10/2.0);
                l11=dt*DPforcephi1(phi1+k10/2.0,phi2,omega1+l10/2.0,omega2);
                k12=dt*(omega1+l11/2.0);
                l12=dt*DPforcephi1(phi1+k11/2.0,phi2,omega1+l11/2.0,omega2);
                k13=dt*(omega1+l12);
                l13=dt*DPforcephi1(phi1+k12,phi2,omega1+l12,omega2);
                //runge kutta phi2
                k20=dt*omega2;
                l20=dt*DPforcephi2(phi1,phi2,omega1,omega2);
                k21=dt*(omega2+l20/2.0);
                l21=dt*DPforcephi2(phi1,phi2+k20/2.0,omega1,omega2+l20/2.0);
                k22=dt*(omega2+l21/2.0);
                l22=dt*DPforcephi2(phi1,phi2+k21/2.0,omega1,omega2+l21/2.0);
                k23=dt*(omega2+l22);
                l23=dt*DPforcephi2(phi1,phi2+k22,omega1,omega2+l22);

                phi1=phi1+(k10+2.0*k11+2.0*k12+k13)/6.0; //Runge-Kutta
                omega1=omega1+(l10+2.0*l11+2.0*l12+l13)/6.0; //Runge-Kutta
                phi2=phi2+(k20+2.0*k21+2.0*k22+k23)/6.0; //Runge-Kutta
                omega2=omega2+(l20+2.0*l21+2.0*l22+l23)/6.0; //Runge-Kutta
                //calculate pixelcoordinates
                px1=float(iwdiv2)+p1l*sin(phi1);
                py1=float(ihdiv2)+p1l*cos(phi1);
                px2=px1+p2l*sin(phi2);
                py2=py1+p2l*cos(phi2); 
                if (loop>iters) { break; }
            }
            
            col=vec4(0.0,0.0,0.0,1.0);
            //graph the result to this pixel based on which quadrant the end of the pendulums is in
            if (px2<float(iwdiv2) && py2<float(ihdiv2)) {  col=vec4(1.0,1.0,0.0,1.0); } //yellow
            if (px2>float(iwdiv2) && py2<float(ihdiv2)) {  col=vec4(1.0,0.0,0.0,1.0); } //red
            if (px2<float(iwdiv2) && py2>float(ihdiv2)) {  col=vec4(0.0,0.0,1.0,1.0); } //blue
            if (px2>float(iwdiv2) && py2>float(ihdiv2)) {  col=vec4(0.0,1.0,0.0,1.0); } //green

            }
            
            //////////////////////////////////////////////////////////////////////////////////////////////////
            // Triple Pendulum
            //////////////////////////////////////////////////////////////////////////////////////////////////
            
            if (triplependulum==true) {
            
            //initial values
            //the angles are being changed per pixel
            phi1=pi/180.0*xp; //p1 angle
            phi2=pi/180.0*yp; //p2 angle
            phi3=pi/180.0*p3angle; //p3angle
            m1=p1mass; //p1 mass
            m2=p2mass; //p2 mass
            m3=p3mass; //p3 mass
            p1l=p1lpercent/100.0*float(ih); //p1 length %
            p2l=p2lpercent/100.0*float(ih); //p2 length %
            p3l=p3lpercent/100.0*float(ih); //p3 length %
            omega1=0.0;
            omega2=0.0;
            omega3=0.0;

            //iterate it - 10000 is the maximum animated time it loops to
            for (int loop=0;loop<10000;loop++)
            {
                //runge kutta phi1
                k10=dt*omega1;
                l10=dt*TPforcephi1(phi1,omega1,phi2,omega2,phi3,omega3);
                k11=dt*(omega1+l10/2.0);
                l11=dt*TPforcephi1(phi1+k10/2.0,omega1+l10/2.0,phi2,omega2,phi3,omega3);
                k12=dt*(omega1+l11/2.0);
                l12=dt*TPforcephi1(phi1+k11/2.0,omega1+l11/2.0,phi2,omega2,phi3,omega3);
                k13=dt*(omega1+l12);
                l13=dt*TPforcephi1(phi1+k12,omega1+l12,phi2,omega2,phi3,omega3);
                //runge kutta phi2
                k20=dt*omega2;
                l20=dt*TPforcephi2(phi1,omega1,phi2,omega2,phi3,omega3);
                k21=dt*(omega2+l20/2.0);
                l21=dt*TPforcephi2(phi1,omega1,phi2+k20/2.0,omega2+l20/2.0,phi3,omega3);
                k22=dt*(omega2+l21/2.0);
                l22=dt*TPforcephi2(phi1,omega1,phi2+k21/2.0,omega2+l21/2.0,phi3,omega3);
                k23=dt*(omega2+l22);
                l23=dt*TPforcephi2(phi1,omega1,phi2+k22,omega2+l22,phi3,omega3);
                //runge kutta phi3
                k30=dt*omega3;
                l30=dt*TPforcephi3(phi1,omega1,phi2,omega2,phi3,omega3);
                k31=dt*(omega3+l30/2.0);
                l31=dt*TPforcephi3(phi1,omega1,phi2,omega2,phi3+k30/2.0,omega3+l30/2.0);
                k32=dt*(omega3+l31/2.0);
                l32=dt*TPforcephi3(phi1,omega1,phi2,omega2,phi3+k31/2.0,omega3+l31/2.0);
                k33=dt*(omega3+l32);
                l33=dt*TPforcephi3(phi1,omega1,phi2,omega2,phi3+k32,omega3+l32);

                phi1=phi1+(k10+2.0*k11+2.0*k12+k13)/6.0; //Runge-Kutta
                omega1=omega1+(l10+2.0*l11+2.0*l12+l13)/6.0; //Runge-Kutta
                phi2=phi2+(k20+2.0*k21+2.0*k22+k23)/6.0; //Runge-Kutta
                omega2=omega2 + (l20+2.0*l21+2.0*l22+l23)/6.0; //Runge-Kutta
                phi3=phi3+(k30+2.0*k31+2.0*k32+k33)/6.0; //Runge-Kutta
                omega3=omega3+(l30+2.0*l31+2.0*l32+l33)/6.0; //Runge-Kutta
                //calculate pixelcoordinates
                px1=float(iwdiv2)+p1l*sin(phi1);
                py1=float(ihdiv2)+p1l*cos(phi1);
                px2=px1+p2l*sin(phi2);
                py2=py1+p2l*cos(phi2);
                px3=px2+p3l*sin(phi3);
                py3=py2+p3l*cos(phi3);
                if (loop>iters) { break; }
            }

            col=vec4(0.0,0.0,0.0,1.0);
            //graph the result to this pixel based on which quadrant the end of the pendulums is in
            if (px3<float(iwdiv2) && py3<float(ihdiv2)) {  col=vec4(1.0,1.0,0.0,1.0); } //yellow
            if (px3>float(iwdiv2) && py3<float(ihdiv2)) {  col=vec4(1.0,0.0,0.0,1.0); } //red
            if (px3<float(iwdiv2) && py3>float(ihdiv2)) {  col=vec4(0.0,0.0,1.0,1.0); } //blue
            if (px3>float(iwdiv2) && py3>float(ihdiv2)) {  col=vec4(0.0,1.0,0.0,1.0); } //green

            }

            //////////////////////////////////////////////////////////////////////////////////////////////////
            // Quadruple Pendulum
            //////////////////////////////////////////////////////////////////////////////////////////////////
            
            if (quadruplependulum==true) {

            //initial values
            //the angles are being changed per pixel
            phi1=pi/180.0*xp; //p1 angle
            phi2=pi/180.0*yp; //p2 angle
            phi3=pi/180.0*p3angle; //p3angle
            phi4=pi/180.0*p4angle; //p3angle
            m1=p1mass; //p1 mass
            m2=p2mass; //p2 mass
            m3=p3mass; //p3 mass
            m4=p4mass; //p4 mass
            p1l=p1lpercent/100.0*float(ih); //p1 length %
            p2l=p2lpercent/100.0*float(ih); //p2 length %
            p3l=p3lpercent/100.0*float(ih); //p3 length %
            p4l=p4lpercent/100.0*float(ih); //p4 length %
            omega1=0.0;
            omega2=0.0;
            omega3=0.0;
            omega4=0.0;

            //iterate it - 10000 is the maximum animated time it loops to
            for (int loop=0;loop<10000;loop++)
            {
                //runge kutta phi1
                k10=dt*omega1;
                l10=dt*QPforcephi1(phi1,omega1,phi2,omega2,phi3,omega3,phi4,omega4);
                k11=dt*(omega1+l10/2.0);
                l11=dt*QPforcephi1(phi1+k10/2.0,omega1+l10/2.0,phi2,omega2,phi3,omega3,phi4,omega4);
                k12=dt*(omega1+l11/2.0);
                l12=dt*QPforcephi1(phi1+k11/2.0,omega1+l11/2.0,phi2,omega2,phi3,omega3,phi4,omega4);
                k13=dt*(omega1+l12);
                l13=dt*QPforcephi1(phi1+k12,omega1+l12,phi2,omega2,phi3,omega3,phi4,omega4);
                //runge kutta phi2
                k20=dt*omega2;
                l20=dt*QPforcephi2(phi1,omega1,phi2,omega2,phi3,omega3,phi4,omega4);
                k21=dt*(omega2+l20/2.0);
                l21=dt*QPforcephi2(phi1,omega1,phi2+k20/2.0,omega2+l20/2.0,phi3,omega3,phi4,omega4);
                k22=dt*(omega2+l21/2.0);
                l22=dt*QPforcephi2(phi1,omega1,phi2+k21/2.0,omega2+l21/2.0,phi3,omega3,phi4,omega4);
                k23=dt*(omega2+l22);
                l23=dt*QPforcephi2(phi1,omega1,phi2+k22,omega2+l22,phi3,omega3,phi4,omega4);
                //runge kutta phi3
                k30=dt*omega3;
                l30=dt*QPforcephi3(phi1,omega1,phi2,omega2,phi3,omega3,phi4,omega4);
                k31=dt*(omega3+l30/2.0);
                l31=dt*QPforcephi3(phi1,omega1,phi2,omega2,phi3+k30/2.0,omega3+l30/2.0,phi4,omega4);
                k32=dt*(omega3+l31/2.0);
                l32=dt*QPforcephi3(phi1,omega1,phi2,omega2,phi3+k31/2.0,omega3+l31/2.0,phi4,omega4);
                k33=dt*(omega3+l32);
                l33=dt*QPforcephi3(phi1,omega1,phi2,omega2,phi3+k32,omega3+l32,phi4,omega4);
                //runge kutta phi4
                k40=dt*omega4;
                l40=dt*QPforcephi4(phi1,omega1,phi2,omega2,phi3,omega3,phi4,omega4);
                k41=dt*(omega4+l40/2.0);
                l41=dt*QPforcephi4(phi1,omega1,phi2,omega2,phi3,omega3,phi4+k40/2.0,omega4+l40/2.0);
                k42=dt*(omega4+l41/2.0);
                l42=dt*QPforcephi4(phi1,omega1,phi2,omega2,phi3,omega3,phi4+k41/2.0,omega4+l41/2.0);
                k43=dt*(omega4+l42);
                l43=dt*QPforcephi4(phi1,omega1,phi2,omega2,phi3,omega3,phi4+k42,omega4+l42);

                phi1=phi1+(k10+2.0*k11+2.0*k12+k13)/6.0; //Runge-Kutta
                omega1=omega1+(l10+2.0*l11+2.0*l12+l13)/6.0; //Runge-Kutta
                phi2=phi2+(k20+2.0*k21+2.0*k22+k23)/6.0; //Runge-Kutta
                omega2=omega2+(l20+2.0*l21+2.0*l22+l23)/6.0; //Runge-Kutta
                phi3=phi3+(k30+2.0*k31+2.0*k32+k33)/6.0; //Runge-Kutta
                omega3=omega3+(l30+2.0*l31+2.0*l32+l33)/6.0; //Runge-Kutta
                phi4=phi4+(k40+2.0*k41+2.0*k42+k43)/6.0; //Runge-Kutta
                omega4=omega4+(l40+2.0*l41+2.0*l42+l43)/6.0; //Runge-Kutta
                //calculate pixelcoordinates
                px1=float(iwdiv2)+p1l*sin(phi1);
                py1=float(ihdiv2)+p1l*cos(phi1);
                px2=px1+p2l*sin(phi2);
                py2=py1+p2l*cos(phi2);
                px3=px2+p3l*sin(phi3);
                py3=py2+p3l*cos(phi3);
                px4=px3+p4l*sin(phi4);
                py4=py3+p4l*cos(phi4);            
                if (loop>iters) { break; }
            }
            
            col=vec4(0.0,0.0,0.0,1.0);
            //graph the result to this pixel based on which quadrant the end of the pendulums is in
            if (px4<float(iwdiv2) && py4<float(ihdiv2)) {  col=vec4(1.0,1.0,0.0,1.0); } //yellow
            if (px4>float(iwdiv2) && py4<float(ihdiv2)) {  col=vec4(1.0,0.0,0.0,1.0); } //red
            if (px4<float(iwdiv2) && py4>float(ihdiv2)) {  col=vec4(0.0,0.0,1.0,1.0); } //blue
            if (px4>float(iwdiv2) && py4>float(ihdiv2)) {  col=vec4(0.0,1.0,0.0,1.0); } //green

            }
            
            
            finalcol+=col;
        }
    }
    glFragColor = vec4(finalcol/float(sqrsamplepixels));
}

