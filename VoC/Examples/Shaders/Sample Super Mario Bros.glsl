#version 420

// original https://www.shadertoy.com/view/Msj3zD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Super Mario Bros. by HLorenzi

#define RGB(r,g,b) vec4(float(r)/255.0,float(g)/255.0,float(b)/255.0,1.0)

#define SPRROW(x,a,b,c,d,e,f,g,h, i,j,k,l,m,n,o,p) (x <= 7 ? SPRROW_H(a,b,c,d,e,f,g,h) : SPRROW_H(i,j,k,l,m,n,o,p))
#define SPRROW_H(a,b,c,d,e,f,g,h) (a+4.0*(b+4.0*(c+4.0*(d+4.0*(e+4.0*(f+4.0*(g+4.0*(h))))))))
#define SECROW(x,a,b,c,d,e,f,g,h) (x <= 3 ? SECROW_H(a,b,c,d) : SECROW_H(e,f,g,h))
#define SECROW_H(a,b,c,d) (a+8.0*(b+8.0*(c+8.0*(d))))
#define SELECT(x,i) mod(floor(i/pow(4.0,float(x))),4.0)
#define SELECTSEC(x,i) mod(floor(i/pow(8.0,float(x))),8.0)

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 sprGround(int x, int y)
{
    float col = 0.0;
    if (y == 15) col = SPRROW(x,1.,0.,0.,0.,0.,0.,0.,0., 0.,2.,1.,0.,0.,0.,0.,1.);
    if (y == 14) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,0.,1.,1.,1.,1.,2.);
    if (y == 13) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,0.,1.,1.,1.,1.,2.);
    if (y == 12) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,0.,1.,1.,1.,1.,2.);
    if (y == 11) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,0.,2.,1.,1.,1.,2.);
    if (y == 10) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,1.,2.,2.,2.,2.,1.);
    if (y ==  9) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,0.,0.,0.,0.,0.,2.);
    if (y ==  8) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,0.,1.,1.,1.,1.,2.);
    
    if (y ==  7) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,0.,1.,1.,1.,1.,2.);
    if (y ==  6) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,2.,0.,1.,1.,1.,1.,2.);
    if (y ==  5) col = SPRROW(x,2.,2.,1.,1.,1.,1.,1.,1., 2.,0.,1.,1.,1.,1.,1.,2.);
    if (y ==  4) col = SPRROW(x,0.,0.,2.,2.,1.,1.,1.,1., 2.,0.,1.,1.,1.,1.,1.,2.);
    if (y ==  3) col = SPRROW(x,0.,1.,0.,0.,2.,2.,2.,2., 0.,1.,1.,1.,1.,1.,1.,2.);
    if (y ==  2) col = SPRROW(x,0.,1.,1.,1.,0.,0.,0.,2., 0.,1.,1.,1.,1.,1.,1.,2.);
    if (y ==  1) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,2., 0.,1.,1.,1.,1.,1.,2.,2.);
    if (y ==  0) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,1., 0.,2.,2.,2.,2.,2.,2.,1.);
    
    col = SELECT(mod(float(x),8.0),col);
    if (col == 0.0) return RGB(247,214,181);
    if (col == 1.0) return RGB(231,90,16);
    return RGB(0,0,0);
}

vec4 sprQuestionBlock(int x, int y)
{
    float col = 0.0;
    if (y == 15) col = SPRROW(x,3.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,3.);
    if (y == 14) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,2.);
    if (y == 13) col = SPRROW(x,0.,1.,2.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,2.,1.,2.);
    if (y == 12) col = SPRROW(x,0.,1.,1.,1.,1.,0.,0.,0., 0.,0.,1.,1.,1.,1.,1.,2.);
    if (y == 11) col = SPRROW(x,0.,1.,1.,1.,0.,0.,2.,2., 2.,0.,0.,1.,1.,1.,1.,2.);
    if (y == 10) col = SPRROW(x,0.,1.,1.,1.,0.,0.,2.,1., 1.,0.,0.,2.,1.,1.,1.,2.);
    if (y ==  9) col = SPRROW(x,0.,1.,1.,1.,0.,0.,2.,1., 1.,0.,0.,2.,1.,1.,1.,2.);
    if (y ==  8) col = SPRROW(x,0.,1.,1.,1.,1.,2.,2.,1., 0.,0.,0.,2.,1.,1.,1.,2.);
    
    if (y ==  7) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,0., 0.,2.,2.,2.,1.,1.,1.,2.);
    if (y ==  6) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,0., 0.,2.,1.,1.,1.,1.,1.,2.);
    if (y ==  5) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 2.,2.,1.,1.,1.,1.,1.,2.);
    if (y ==  4) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,0., 0.,0.,1.,1.,1.,1.,1.,2.);
    if (y ==  3) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,0., 0.,2.,1.,1.,1.,1.,1.,2.);
    if (y ==  2) col = SPRROW(x,0.,1.,2.,1.,1.,1.,1.,1., 2.,2.,1.,1.,1.,2.,1.,2.);
    if (y ==  1) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,2.);
    if (y ==  0) col = SPRROW(x,2.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,2.);
    
    if (y < 0 || y > 15) return RGB(107,140,255);
    
    col = SELECT(mod(float(x),8.0),col);
    if (col == 0.0) return RGB(231,90,16);
    if (col == 1.0) return RGB(255,165,66);
    if (col == 2.0) return RGB(0,0,0);
    return RGB(107,140,255);
}

vec4 sprUsedBlock(int x, int y)
{
    float col = 0.0;
    if (y == 15) col = SPRROW(x,3.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,3.);
    if (y == 14) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y == 13) col = SPRROW(x,0.,1.,0.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,0.,1.,0.);
    if (y == 12) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y == 11) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y == 10) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y ==  9) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y ==  8) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    
    if (y ==  7) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y ==  6) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y ==  5) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y ==  4) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y ==  3) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y ==  2) col = SPRROW(x,0.,1.,0.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,0.,1.,0.);
    if (y ==  1) col = SPRROW(x,0.,1.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,1.,0.);
    if (y ==  0) col = SPRROW(x,3.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,3.);
    
    if (y < 0 || y > 15) return RGB(107,140,255);
    
    col = SELECT(mod(float(x),8.0),col);
    if (col == 0.0) return RGB(0,0,0);
    if (col == 1.0) return RGB(231,90,16);
    return RGB(107,140,255);
}

vec4 sprMarioJump(int x, int y)
{
    float col = 0.0;
    if (y == 15) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,2.,2.,2.);
    if (y == 14) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,1.,0.,0.,2.,2.,2.);
    if (y == 13) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,1.,1.,1.,1.,2.,2.);
    if (y == 12) col = SPRROW(x,0.,0.,0.,0.,0.,3.,3.,3., 2.,2.,3.,2.,0.,3.,3.,3.);
    if (y == 11) col = SPRROW(x,0.,0.,0.,0.,3.,2.,3.,2., 2.,2.,3.,2.,2.,3.,3.,3.);
    if (y == 10) col = SPRROW(x,0.,0.,0.,0.,3.,2.,3.,3., 2.,2.,2.,3.,2.,2.,2.,3.);
    if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,3.,3.,2.,2., 2.,2.,3.,3.,3.,3.,3.,0.);
    if (y ==  8) col = SPRROW(x,0.,0.,0.,0.,0.,0.,2.,2., 2.,2.,2.,2.,2.,3.,0.,0.);
    
    if (y ==  7) col = SPRROW(x,0.,0.,3.,3.,3.,3.,3.,1., 3.,3.,3.,1.,3.,0.,0.,0.);
    if (y ==  6) col = SPRROW(x,0.,3.,3.,3.,3.,3.,3.,3., 1.,3.,3.,3.,1.,0.,0.,3.);
    if (y ==  5) col = SPRROW(x,2.,2.,3.,3.,3.,3.,3.,3., 1.,1.,1.,1.,1.,0.,0.,3.);
    if (y ==  4) col = SPRROW(x,2.,2.,2.,0.,1.,1.,3.,1., 1.,2.,1.,1.,2.,1.,3.,3.);
    if (y ==  3) col = SPRROW(x,0.,2.,0.,3.,1.,1.,1.,1., 1.,1.,1.,1.,1.,1.,3.,3.);
    if (y ==  2) col = SPRROW(x,0.,0.,3.,3.,3.,1.,1.,1., 1.,1.,1.,1.,1.,1.,3.,3.);
    if (y ==  1) col = SPRROW(x,0.,3.,3.,3.,1.,1.,1.,1., 1.,1.,1.,0.,0.,0.,0.,0.);
    if (y ==  0) col = SPRROW(x,0.,3.,0.,0.,1.,1.,1.,1., 0.,0.,0.,0.,0.,0.,0.,0.);
    
    col = SELECT(mod(float(x),8.0),col);
    if (col == 0.0) return RGB(0,0,0);
    if (col == 1.0) return RGB(177,52,37);
    if (col == 2.0) return RGB(227,157,37);
    if (col == 3.0) return RGB(106,107,4);
    return RGB(0,0,0);
}

vec4 sprMarioWalk3(int x, int y)
{
    float col = 0.0;
    if (y == 15) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
    if (y == 14) col = SPRROW(x,0.,0.,0.,0.,1.,1.,1.,1., 1.,1.,1.,1.,1.,0.,0.,0.);
    if (y == 13) col = SPRROW(x,0.,0.,0.,0.,3.,3.,3.,2., 2.,3.,2.,0.,0.,0.,0.,0.);
    if (y == 12) col = SPRROW(x,0.,0.,0.,3.,2.,3.,2.,2., 2.,3.,2.,2.,2.,0.,0.,0.);
    if (y == 11) col = SPRROW(x,0.,0.,0.,3.,2.,3.,3.,2., 2.,2.,3.,2.,2.,2.,0.,0.);
    if (y == 10) col = SPRROW(x,0.,0.,0.,3.,3.,2.,2.,2., 2.,3.,3.,3.,3.,0.,0.,0.);
    if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 2.,2.,2.,2.,0.,0.,0.,0.);
    if (y ==  8) col = SPRROW(x,0.,0.,3.,3.,3.,3.,1.,1., 3.,3.,0.,0.,0.,0.,0.,0.);
    
    if (y ==  7) col = SPRROW(x,2.,2.,3.,3.,3.,3.,1.,1., 1.,3.,3.,3.,2.,2.,2.,0.);
    if (y ==  6) col = SPRROW(x,2.,2.,2.,0.,3.,3.,1.,2., 1.,1.,1.,3.,3.,2.,2.,0.);
    if (y ==  5) col = SPRROW(x,2.,2.,0.,0.,1.,1.,1.,1., 1.,1.,1.,0.,0.,3.,0.,0.);
    if (y ==  4) col = SPRROW(x,0.,0.,0.,1.,1.,1.,1.,1., 1.,1.,1.,1.,3.,3.,0.,0.);
    if (y ==  3) col = SPRROW(x,0.,0.,1.,1.,1.,1.,1.,1., 1.,1.,1.,1.,3.,3.,0.,0.);
    if (y ==  2) col = SPRROW(x,0.,3.,3.,1.,1.,1.,0.,0., 0.,1.,1.,1.,3.,3.,0.,0.);
    if (y ==  1) col = SPRROW(x,0.,3.,3.,3.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
    if (y ==  0) col = SPRROW(x,0.,0.,3.,3.,3.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
    
    col = SELECT(mod(float(x),8.0),col);
    if (col == 0.0) return RGB(0,0,0);
    if (col == 1.0) return RGB(177,52,37);
    if (col == 2.0) return RGB(227,157,37);
    if (col == 3.0) return RGB(106,107,4);
    return RGB(0,0,0);
}

vec4 sprMarioWalk2(int x, int y)
{
    float col = 0.0;
    if (y == 15) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
    if (y == 14) col = SPRROW(x,0.,0.,0.,0.,1.,1.,1.,1., 1.,1.,1.,1.,1.,0.,0.,0.);
    if (y == 13) col = SPRROW(x,0.,0.,0.,0.,3.,3.,3.,2., 2.,3.,2.,0.,0.,0.,0.,0.);
    if (y == 12) col = SPRROW(x,0.,0.,0.,3.,2.,3.,2.,2., 2.,3.,2.,2.,2.,0.,0.,0.);
    if (y == 11) col = SPRROW(x,0.,0.,0.,3.,2.,3.,3.,2., 2.,2.,3.,2.,2.,2.,0.,0.);
    if (y == 10) col = SPRROW(x,0.,0.,0.,3.,3.,2.,2.,2., 2.,3.,3.,3.,3.,0.,0.,0.);
    if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 2.,2.,2.,2.,0.,0.,0.,0.);
    if (y ==  8) col = SPRROW(x,0.,0.,0.,0.,3.,3.,1.,3., 3.,3.,0.,0.,0.,0.,0.,0.);
    
    if (y ==  7) col = SPRROW(x,0.,0.,0.,3.,3.,3.,3.,1., 1.,3.,3.,0.,0.,0.,0.,0.);
    if (y ==  6) col = SPRROW(x,0.,0.,0.,3.,3.,3.,1.,1., 2.,1.,1.,2.,0.,0.,0.,0.);
    if (y ==  5) col = SPRROW(x,0.,0.,0.,3.,3.,3.,3.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
    if (y ==  4) col = SPRROW(x,0.,0.,0.,1.,3.,3.,2.,2., 2.,1.,1.,1.,0.,0.,0.,0.);
    if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,1.,3.,2.,2., 1.,1.,1.,0.,0.,0.,0.,0.);
    if (y ==  2) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 3.,3.,3.,0.,0.,0.,0.,0.);
    if (y ==  1) col = SPRROW(x,0.,0.,0.,0.,0.,3.,3.,3., 3.,3.,3.,3.,0.,0.,0.,0.);
    if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,3.,3.,3., 3.,0.,0.,0.,0.,0.,0.,0.);
    
    col = SELECT(mod(float(x),8.0),col);
    if (col == 0.0) return RGB(0,0,0);
    if (col == 1.0) return RGB(177,52,37);
    if (col == 2.0) return RGB(227,157,37);
    if (col == 3.0) return RGB(106,107,4);
    return RGB(0,0,0);
}

vec4 sprMarioWalk1(int x, int y)
{
    float col = 0.0;
    if (y == 15) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
    if (y == 14) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,1.,0.,0.,0.,0.,0.);
    if (y == 13) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,1.,1.,1.,1.,0.,0.);
    if (y == 12) col = SPRROW(x,0.,0.,0.,0.,0.,3.,3.,3., 2.,2.,3.,2.,0.,0.,0.,0.);
    if (y == 11) col = SPRROW(x,0.,0.,0.,0.,3.,2.,3.,2., 2.,2.,3.,2.,2.,2.,0.,0.);
    if (y == 10) col = SPRROW(x,0.,0.,0.,0.,3.,2.,3.,3., 2.,2.,2.,3.,2.,2.,2.,0.);
    if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,3.,3.,2.,2., 2.,2.,3.,3.,3.,3.,0.,0.);
    if (y ==  8) col = SPRROW(x,0.,0.,0.,0.,0.,0.,2.,2., 2.,2.,2.,2.,2.,0.,0.,0.);
    
    if (y ==  7) col = SPRROW(x,0.,0.,0.,0.,0.,3.,3.,3., 3.,1.,3.,0.,2.,0.,0.,0.);
    if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,2.,3.,3.,3., 3.,3.,3.,2.,2.,2.,0.,0.);
    if (y ==  5) col = SPRROW(x,0.,0.,0.,2.,2.,1.,3.,3., 3.,3.,3.,2.,2.,0.,0.,0.);
    if (y ==  4) col = SPRROW(x,0.,0.,0.,3.,3.,1.,1.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
    if (y ==  3) col = SPRROW(x,0.,0.,0.,3.,1.,1.,1.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
    if (y ==  2) col = SPRROW(x,0.,0.,3.,3.,1.,1.,1.,0., 1.,1.,1.,0.,0.,0.,0.,0.);
    if (y ==  1) col = SPRROW(x,0.,0.,3.,0.,0.,0.,0.,3., 3.,3.,0.,0.,0.,0.,0.,0.);
    if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,3., 3.,3.,3.,0.,0.,0.,0.,0.);
    
    col = SELECT(mod(float(x),8.0),col);
    if (col == 0.0) return RGB(0,0,0);
    if (col == 1.0) return RGB(177,52,37);
    if (col == 2.0) return RGB(227,157,37);
    if (col == 3.0) return RGB(106,107,4);
    return RGB(0,0,0);
}

vec4 getTile(int t, int x, int y)
{
    if (t == 0) return RGB(107,140,255);
    if (t == 1) return sprGround(x,y);
    if (t == 2) return sprQuestionBlock(x,y);
    if (t == 3) return sprUsedBlock(x,y);
    
    return RGB(107,140,255);
}

int getSection(int s, int x, int y)
{
    float col = 0.0;
    if (s == 0) {
        if (y == 6) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 5) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 4) col = SECROW(x,0.,0.,3.,3.,3.,0.,0.,0.);
        if (y == 3) col = SECROW(x,0.,0.,2.,2.,2.,0.,0.,0.);
        if (y == 2) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 1) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y <= 0) col = SECROW(x,1.,1.,1.,1.,1.,1.,1.,1.);
    }
    if (s == 1) {
        if (y == 6) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 5) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 4) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 3) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 2) col = SECROW(x,0.,0.,0.,0.,0.,1.,0.,0.);
        if (y == 1) col = SECROW(x,0.,0.,0.,1.,1.,1.,0.,0.);
        if (y <= 0) col = SECROW(x,1.,1.,1.,1.,1.,1.,1.,1.);
    }
    if (s == 2) {
        if (y == 6) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 5) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 4) col = SECROW(x,0.,0.,3.,0.,0.,3.,0.,0.);
        if (y == 3) col = SECROW(x,0.,0.,2.,0.,0.,2.,0.,0.);
        if (y == 2) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 1) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y <= 0) col = SECROW(x,1.,1.,1.,1.,1.,1.,1.,1.);
    }
    if (s == 3) {
        if (y == 6) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 5) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 4) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 3) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 2) col = SECROW(x,0.,0.,0.,1.,1.,0.,0.,0.);
        if (y == 1) col = SECROW(x,0.,0.,0.,1.,1.,1.,0.,0.);
        if (y <= 0) col = SECROW(x,1.,1.,1.,1.,1.,1.,1.,1.);
    }
    if (s == 4) {
        if (y == 6) col = SECROW(x,0.,0.,0.,0.,3.,0.,0.,0.);
        if (y == 5) col = SECROW(x,0.,0.,0.,0.,2.,0.,0.,0.);
        if (y == 4) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 3) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 2) col = SECROW(x,0.,0.,0.,1.,1.,1.,0.,0.);
        if (y == 1) col = SECROW(x,0.,0.,0.,1.,1.,1.,0.,0.);
        if (y <= 0) col = SECROW(x,1.,1.,1.,1.,1.,1.,1.,1.);
    }
    if (s == 5) {
        if (y == 6) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 5) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 4) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 3) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 2) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y == 1) col = SECROW(x,0.,0.,0.,0.,0.,0.,0.,0.);
        if (y <= 0) col = SECROW(x,1.,1.,1.,0.,0.,1.,1.,1.);
    }
    
    
    
    return int(SELECTSEC(mod(float(x),4.0),col));
}

int getBlock(int x, int y)
{
    if (y > 6) return 0;
    
    int section = int(rand(vec2(int(float(x) / 8.0),3.0)) * 6.0);
    int sectionX = int(mod(float(x), 8.0));
    
    return getSection(section,sectionX,y - int(rand(vec2(section,2.0)) * 0.0));
}

bool isSolid(int b)
{
    return (b != 0);
}

void main(void)
{
    const float gameSpeed = 60.0;
    
    float x = gl_FragCoord.x / 2.0;
    float y = gl_FragCoord.y / 2.0;
    if (resolution.y >= 640.0) {
        x /= 2.0;
        y /= 2.0;
    }
    
    y -= 8.0;

    int firstBlockX = int((time * gameSpeed) / 16.0);
    int blockX = int((x + time * gameSpeed) / 16.0);
    int blockY = int(y / 16.0);
    
    int block = getBlock(blockX,blockY);
    
    int subx = int(mod((x + time * gameSpeed),16.0));
    int suby = int(mod(y,16.0));
    if (block == 2) {
        if (blockX - firstBlockX == 5) {
            suby -= int(max(0.0,(sin(mod((time * gameSpeed / 16.0),1.0) * 3.141592 * 1.5) * 8.0)));
        }
        
        if ((floor((x + time * gameSpeed) / 16.0) - (time * gameSpeed) / 16.0) < 4.25) block = 3;
    } else if (block == 3) {
        block = 2;
        suby += 16;
        if (blockX - firstBlockX == 5) {
            suby -= int(max(0.0,(sin(mod((time * gameSpeed / 16.0),1.0) * 3.141592 * 1.5) * 8.0)));
        }
    }
    glFragColor = getTile(block,subx,suby);
    
    
    
    const float startX = -32.0;
    const float endX = 80.0;
    
    if (x >= endX && x < endX + 16.0) {
        float screenX = time * gameSpeed;
        
        float marioX = screenX + startX;
        float marioY = 16.0;
        float marioXSpd = 4.0;
        float marioYSpd = 0.0;
        
        for(int i = 1; i < 8; i++) {
            if (!isSolid(getBlock(firstBlockX, i))) {
                marioY = float(i) * 16.0;
                break;
            }
        }
        
        const int simSteps = int((endX - startX) / 4.0);
        
        float lastX = 0.0;
        float lastY = 0.0;
        
        bool onGround = false;
        for(int sim = 0; sim < simSteps; sim++) {
            lastX = marioX;
            lastY = marioY;
            
            onGround = false;
            if (isSolid(getBlock(int(marioX / 16.0) + 1, int(marioY / 16.0)))) {
                marioY = (floor(marioY / 16.0) * 16.0) + 16.0;
            }
            
            marioYSpd -= 2.5;
            marioY += marioYSpd;
            
            if (marioYSpd > 0.0) {
                if (isSolid(getBlock(int(floor((marioX + 12.0) / 16.0)), int(floor((marioY + 15.9) / 16.0))))) {
                    marioYSpd *= -0.5;
                    marioY = (floor(marioY / 16.0) * 16.0);
                }
            }
            
            if (marioYSpd < 0.0) {
                if (isSolid(getBlock(int(floor((marioX) / 16.0)), int(floor(marioY / 16.0)))) ||
                    isSolid(getBlock(int(floor((marioX + 15.9) / 16.0)), int(floor(marioY / 16.0))))) {
                    marioYSpd = 0.0;
                    marioY = (floor(marioY / 16.0) * 16.0) + 16.0;
                    onGround = true;
                }
            }
            
            marioX += marioXSpd;
            if (onGround) {
                if (!isSolid(getBlock(int((marioX) / 16.0) + 1,0))) {
                    marioYSpd = 15.5;
                } else if (isSolid(getBlock(int((marioX + 48.0) / 16.0), int((marioY + 24.0) / 16.0)))) {
                    marioYSpd = 15.5;
                } else if (isSolid(getBlock(int((marioX) / 16.0) + 2, int((marioY + 8.0) / 16.0)))) {
                    marioYSpd = 12.5;
                } else if (getBlock(int((marioX) / 16.0) + 1, int((marioY + 8.0) / 16.0) + 2) == 2) {
                    marioYSpd = 15.5;
                }
                
            }
        }
        
        marioY = mix(lastY,marioY,mod(time * 15.0,1.0)) - 1.0;
        
        if (y >= marioY && y < marioY + 16.0) {
            vec4 spr = vec4(0,0,0,0);
            if (onGround) {
                int f = int(mod(time * 10.0, 3.0));
                if (f == 0) spr = sprMarioWalk1(int(x - (marioX - screenX)),int(y - marioY));
                if (f == 1) spr = sprMarioWalk2(int(x - (marioX - screenX)),int(y - marioY));
                if (f == 2) spr = sprMarioWalk3(int(x - (marioX - screenX)),int(y - marioY));
            } else {
                spr = sprMarioJump(int(x - (marioX - screenX)),int(y - marioY));
            }
            if (spr.x != 0.0) glFragColor = spr;
        }
    }
}
