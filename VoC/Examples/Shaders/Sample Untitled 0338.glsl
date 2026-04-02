#version 420

//    Vasarello

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

void main( void )
{
vec2 R = resolution.xy, P;
vec2 U = gl_FragCoord.xy;
U = (U+U-R)/R.y * 12.;

vec4 O=vec4(0.);
if (abs(U.x) > 12.) return;
float l;

#define S(x,y) P = vec2(x,y); l = length(U-P); if (l < 5.5) U = (U-P) / (3.-l*l/15.) + P

float t=time/5.;
float r=6.;
S( r*sin(t), r*cos(t)); // bubbles
S( r*sin(t+6.28/3.), r*cos(t+6.28/3.));
S( r*sin(t+6.28*2./3.), r*cos(t+6.28*2./3.));

U *= 6.28;
float h = cos(U.y/1.5), 
s = U.x, e=100./R.y, X, Y;

#define F(x,y,h,c1,c2,c3) X=sin(U.r/x),Y=sin(U.g/y); O= X*Y*h>0. ? s>-10.?c1:c2 :c3; O*= min(1.,8.*min(abs(X),abs(Y)))

F( .87, 1.5, 1., vec4(1,0,0,1), vec4(.7,.4,0,1), vec4(.4+.4*cos(s/12.)) ); // red & white faces

if (abs(h)>.5) {
U *= mat2(.575,1,.575,-1); // U = mat2(.5,.5,.87,-.87)*U/.87;
F( 1.,1., h, vec4(0,0,1,1), vec4(.4,0,.7,1), O ); // blue faces
}
glFragColor=O;

}
