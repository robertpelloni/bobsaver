#version 420

// original https://www.shadertoy.com/view/fdSSDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float ds;

vec2 hash(vec2 p)
{
    vec3 p3 = fract(p.xyx * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx).xy;
}

vec2 noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

mat2 rot(float a){
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float map(vec2 p)
{
    float d=1000.;
    for (int i=0; i<50; i++)
    {
        vec2 pr=noise(vec2(float(i)*.7+time*.05)).xy-.5;
        pr.x*=1.7;
        d=smin(d,pow(length(p+pr),2.)-.001,.01);
    }
    ds=d;
    return d;
}

void main(void)
{
    vec2 p=(gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    vec3 col1=vec3(1.,.6,.3);
    vec3 col2=vec3(.4,.7,1.);
//    float d=map(p);
    vec3 ldir=normalize(vec3(1.,2.,.7));
    vec3 amb=col1*.8;
    vec2 eps=vec2(0.,.01);
    vec3 n=normalize(vec3(map(p+eps.yx),map(p+eps.xy),eps.y*.3)-map(p));
    float dif=smoothstep(.0,1.,max(0.,dot(ldir,n)));
    float dr=smoothstep(.001,0.,ds);
    col1-=smoothstep(.5,.6,fract(p.y*20.))*.2;
    glFragColor=vec4(mix(mix(col1,col2,smoothstep(-.5,.3,p.y))*.7,amb+dif,dr),1.);
}

