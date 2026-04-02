#version 420

// original https://www.shadertoy.com/view/Msfcz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash( vec2 p ) // replace this by something better
{
    p = vec2( dot(p,vec2(127.1,311.7)),
              dot(p,vec2(269.5,183.3)) );

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2 i = floor( p + (p.x+p.y)*K1 );
    
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = step(a.yx,a.xy);    
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0*K2;

    vec3 h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );

    vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));

    return dot( n, vec3(70.0) );
    
}

float fnoise(in vec2 p)
{
    float f = 0.0;
    p *= 5.0;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise( p ); p = m*p;
    f += 0.2500*noise( p ); p = m*p;
    f += 0.1250*noise( p ); p = m*p;
    f += 0.0625*noise( p ); p = m*p;
    return(f);
}

// -----------------------------------------------

float cloud(in vec2 uv, float cloudy, float time) {
    uv += 0.05*pow(sin(time+uv.x*4.0),2.0);
    float hh = 0.9+0.1*fnoise(uv*1.7+vec2(time*-4.5,time*-3.7));
    float h = 0.9+0.1*fnoise(uv+vec2(time*2.1,time*1.7));
    uv += vec2(time*0.7,time*0.9);
    float d = cloudy*0.33+0.4*fnoise(uv*0.25)+0.2*h+0.5*hh;
    d = smoothstep(0.4,0.9,clamp(d*d,0.0,1.0));

    return (d*h);
}

vec3 cloudmix(vec3 lightcolor,vec3 skycolor,float density, float weight) {
    vec3 cloudcolor = mix(lightcolor,skycolor*0.5,smoothstep(0.2,0.8,density*0.5));
    vec3 result = mix(skycolor,cloudcolor,weight*smoothstep(0.2,0.9,density*3.0));
    return(result);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float time = time*0.02;
    float cloudy = 0.5+0.6*sin(time*20.0);
    vec3 lightcolor = vec3(1.0);
    vec3 skycolor =mix(vec3(111./255.0,178./255.0,197./255.0),vec3(19./255.0,86./255.0,129./255.0),uv.y);
    vec3 result = vec3(0);
    float strato = cloud(uv*vec2(0.44,0.88), cloudy*0.5, time*0.33);
    result = cloudmix(lightcolor,skycolor,strato,0.33);
    float cumu = cloud(uv*2.0, cloudy, time);
    result = cloudmix(lightcolor,result,cumu,0.9);
    //result = cloudmix(lightcolor,skycolor,cumu,1.0);
    
    glFragColor = vec4( result, 1.0 );
}
