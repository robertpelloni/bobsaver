#version 420

// original https://www.shadertoy.com/view/tlcyRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define C gl_FragCoord.xy
#define T time
#define M mouse*resolution.xy

float pixelSize = 0.;
float pi = 3.14159;
float e = 2.718281828459;

vec3 magma(float t) {

    const vec3 c0 = vec3(-0.002136485053939582, -0.000749655052795221, -0.005386127855323933);
    const vec3 c1 = vec3(0.2516605407371642, 0.6775232436837668, 2.494026599312351);
    const vec3 c2 = vec3(8.353717279216625, -3.577719514958484, 0.3144679030132573);
    const vec3 c3 = vec3(-27.66873308576866, 14.26473078096533, -13.64921318813922);
    const vec3 c4 = vec3(52.17613981234068, -27.94360607168351, 12.94416944238394);
    const vec3 c5 = vec3(-50.76852536473588, 29.04658282127291, 4.23415299384598);
    const vec3 c6 = vec3(18.65570506591883, -11.48977351997711, -5.601961508734096);

    t *= 2.;
    if(t >= 1.)
    {
        t = 2. - t;
    }
    
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

vec3 c0 = vec3(0,2,5)/255.;
vec3 c1 = vec3(8,45,58)/255.;
vec3 c2 = vec3(38,116,145)/255.;
vec3 c3 = vec3(167,184,181)/260.;
vec3 c4 = vec3(38,116,145)/255.;

vec3 cmap(float t) {
    vec3 col = vec3(0);
    col = mix( c0,  c1, smoothstep(0. , .2, t));
    col = mix( col, c2, smoothstep(.2, .4 , t));
    col = mix( col, c3, smoothstep(.4 , .6, t));
    col = mix( col, c4, smoothstep(.6,  .8, t));
    col = mix( col, c0, smoothstep(.8, 1.,  t));
    return col;
}

vec2 cadd( vec2 a, float s ) { return vec2( a.x+s, a.y ); }
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }
vec2 csqrt( vec2 z ) { float m = length(z); return sqrt( 0.5*vec2(m+z.x, m-z.x) ) * vec2( 1.0, sign(z.y) ); }
vec2 conj( vec2 z ) { return vec2(z.x,-z.y); }
vec2 cpow( vec2 z, float n ) { float r = length( z ); float a = atan( z.y, z.x ); 
                               return pow( r, n )*vec2( cos(a*n), sin(a*n) ); }
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 map(vec2 z, vec2 c, float n) {
    float b = 4., i=0.;
    float ii = n;
    
    // x = x - f(x)/f'(x)
 
    
    //c = (2.*mouse*resolution.xy.xy-R) / R.y;
    //z = vec2(1,0);
    
    vec2 z_prev = z;
    for(i=0.; i < n; i++) {
        
        
        z_prev = z;
        
        float p = 3.;
        float t = time / 40.;
        vec2 a = vec2(cos(13.*t), sin(15.*t));
        float r = 2.*(cos(time)*.5 + .5) + .3;
        z = z - cmul(a, cdiv(cpow(z, 3.0) - vec2(1,0), cmul(vec2(3.,0), cpow(z, 2.0))));
        if( abs(length(z-z_prev)) < 0.0001){
            ii = min(ii, i);
        }
    }   
    return vec3(z, ii / n);
}

void main(void)
{
    vec2 uv = (2.*C-R)/R.y;
    uv *= 1.2;
    float t = time / 4.;
    pixelSize = 1./R.y;
    vec3 m = map(uv, uv, 60.);
    vec2 z = m.xy;

    // Calculate polar coordinates
    float r = sqrt(dot(z, z));
    float theta = atan(z.y, z.x+0.000000001);
     
    // Normalize theta
    float thetaNorm = (pi + theta) / (2.*pi);
    
    // Color the angle based on rainbow colors, and show the distance
    float absW = log2(length(m.z));
    float a = 0.0;
    vec3 col = hsb2rgb(vec3(thetaNorm, 1., 1.) +.1) * (1.0 - a + a*absW);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
