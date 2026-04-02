#version 420

// original https://www.shadertoy.com/view/wlsSDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 3

#define MAXITER 1000
#define MINZDIFF 0.1
// zoom exponents
#define MINZOOM -3.0
#define MAXZOOM 9.0
#define T 10.0

#define TAU 6.28

// for z^3-1=0
//#define CX -0.79366
//#define CY -0.000982
//#define NEWTON_STEP newton_step_z3

// for z^5-1=0
#define CX -0.76701
#define CY -0.253007
#define NEWTON_STEP newton_step_z5

// solving z^3-1=0
// f=z^3-1, f'=3z^2, z_n+1 = z_n - f(z_n)/f'(z_n) = (2/3)z_n + (1/3)z^-2
vec2 newton_step_z3(vec2 z)
{
    // z=x+yi
    // z^-2 = (x^2 - y^2)/(x^2 + y^2)^2 - (2*x*y/(x^2 + x^2)^2)i [thanks wolfram alhpa]
    float x2 = z.x*z.x;
    float y2 = z.y*z.y;
    float zmag22inv = 1.0/((x2+y2)*(x2+y2));
    return 0.6667*z + 0.3333*vec2((x2-y2)*zmag22inv, -2.0*z.x*z.y*zmag22inv);
}

// solving z^5-1=0
// f=z^5-1, f'=5z^4, z_n+1 = z_n - f(z_n)/f'(z_n) = (4/5)z_n + (1/5)z^-4
vec2 newton_step_z5(vec2 z)
{
    // z^-4 = (x^4 + y^4 - 6 x^2 y^2)/(x^2 + y^2)^4 + (4(x y^3 - x^3 y)/(x^2 + y^2)^4)i
    float x2 = z.x*z.x;
    float y2 = z.y*z.y;
    float zmag24inv = 1.0/pow(x2+y2, 4.0);
    return 0.8*z + 0.2*vec2((x2*x2+y2*y2-6.0*x2*y2)*zmag24inv, 4.0*(z.x*z.y*y2 - z.x*x2*z.y)*zmag24inv);
}

void main(void)
{
    float zoom_exp = 0.5*(MAXZOOM-MINZOOM)*cos(0.2*time)-0.5*(MAXZOOM+MINZOOM);
    vec3 col = vec3(0.0);
    
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
    vec2 z = vec2(CX,CY)+exp(zoom_exp)*(gl_FragCoord.xy+vec2(float(m),float(n))/float(AA)-0.5*resolution.xy)/resolution.y;
#else
    vec2 z = vec2(CX,CY)+exp(zoom_exp)*(gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
#endif
    
    int i;
    vec2 z_prev;
    for (i=0; i<MAXITER; i++) {
        z_prev = z;
        z = NEWTON_STEP(z);
        if (length(z-z_prev)<MINZDIFF) break;
    }
    
    float phi = atan(z.y, z.x); // get hue angle
    float mu = log(float(i) + length(z-z_prev)/MINZDIFF); // smooth the exit iteration
    mu = 1.0 - mu/(mu+T); //transform to between 0 and 1
    phi += 0.5*TAU*mu; // rotate hue
    col += 0.5+0.5*cos(phi+vec3(0, 0.33*TAU, 0.66*TAU));
#if AA>1
    }
    col /= float(AA*AA);
#endif
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
