#version 420

// original https://www.shadertoy.com/view/wlscRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Great lecture on the subject! https://youtu.be/ZxYOEwM6Wbk?t=2177

#define rot(j) mat2(cos(j),sin(j),sin(j),cos(j))

#define pi acos(-1.)

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + b.y*b.x ); }
// cpolar() and cpow() I borrowed from some shader on shadertoy! not sure which
vec2 cpolar( float k , float t ){  return k*vec2(cos(t),sin(t));}
vec2 cpow( vec2 z , float k ) { return cpolar(pow(length(z),k) , k*atan(z.y,z.x) ); }

float factoriel(float a){
    float f = 1.;
    for(float i = 1.; i <= a; i++){
        f *= i;
    }
    return f;
}

// from iq
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
        
    
    vec2 z = vec2(1,0.);
    
    
    
    col = mix(col,vec3(1.,1.,1.),smoothstep(1.*dFdx(uv.x),0.,abs(length(uv.x)) - 0.002));
    
    col = mix(col,vec3(1.,1.,1.),smoothstep(1.*dFdx(uv.x),0.,abs(length(uv.y)) - 0.002));
    
    float modD = 0.125;
    col = mix(col,vec3(1.,1.,1.),smoothstep(1.*dFdx(uv.x),0.,max(
        abs(length(mod(uv.x - modD/2.,modD) - modD/2.)) - 0.002,
        abs(uv.y) - 0.01                                            )));
    
    col = mix(col,vec3(1.,1.,1.),smoothstep(1.*dFdx(uv.x),0.,max(
        abs(length(mod(uv.y - modD/2.,modD) - modD/2.)) - 0.002,
        abs(uv.x) - 0.01                                            )));
    
    
    col = mix(col,vec3(0.2,0.4,0.9),smoothstep(1.*dFdx(uv.x),0.,abs(length(uv) - 0.25) - 0.002));
    
    
    // lines
    
    float dotSz = 0.01;
    
    float dDots = length(uv - z/4.) - dotSz;
    float dLines = 10e5;
    float theta = pi*1. - sin(time/2.)*pi*0.75;
    vec2 numerator = vec2(0,theta);
    for(float i = 1.; i < 20.; i++){
        vec2 denominator = vec2(factoriel(i),0.);
        vec2 oldz = z;
        z +=  cpow(numerator,i) / denominator.x;
           
        dLines = min(dLines, sdSegment(uv,oldz/4.,z/4.) - 0.002);
        dDots = min(dDots, length(uv - z/4.) - dotSz);
    
    }
    
    col = mix(col,vec3(1.,0.4,0.2),smoothstep(1.*dFdx(uv.x),0.,dLines));
    col = mix(col,vec3(1.,0.2,0.4),smoothstep(1.*dFdx(uv.x),0.,dDots));
    
    col = pow(col,vec3(0.454545));
    
    glFragColor = vec4(col,1.0);
}
