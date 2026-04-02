#version 420

// original https://www.shadertoy.com/view/ltdXR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PRECI 0.001
#define tmax 300.0
#define tmin 0.0

float iqhash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( vec3 x )
{
    // The noise function returns a value in the range -1.0f -> 1.0f
    vec3 p = floor(x);
    vec3 f = fract(x);

    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
    float v = mix(mix(mix( iqhash(n+0.0  ), iqhash(n+1.0  ),f.x),
                   mix( iqhash(n+57.0 ), iqhash(n+58.0 ),f.x),f.y),
               mix(mix( iqhash(n+113.0), iqhash(n+114.0),f.x),
                   mix( iqhash(n+170.0), iqhash(n+171.0),f.x),f.y),f.z);
    return -1.0 + 2.0 * v;
}

float noise11( float x ){
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix(iqhash(p), iqhash(p + 1.0), f);
}

float map(vec3 p){
    vec3 b = vec3(2.0,4.5, 0.5);
    vec3 d = abs(p-vec3(0.0, 0.5, 1.7)) - b;
    float box = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    return box;
}

float raymarch(vec3 ro, vec3 rd){
    float t = tmin;
    for (int i = 0; i < 512; ++i){
        float dist = map(ro + rd*t);
        
        if (dist <= PRECI){
            break;
        }
        
        if (t>tmax){
            break;
        }
        
        t = t + dist;
    }
    
    return t;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

float cloudmap(vec3 p){
    //p = p * 2.0;
    vec3 q = p - vec3(0.0,0.0,0.02)* time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q ); q = q*2.02;
    f += 0.03125*noise( q );
    return 2.0 - length(p) + f * 5.0;

}

const vec3 sundir = normalize(vec3(0.0, 10.0, 2.9));

vec4 integrate( in vec4 sum, in float dif, in float den, in vec3 bgcol, in float t )
{
    // lighting
    vec3 lin = vec3(0.65,0.7,0.75)*0.4 + vec3(1.0, 0.5, 0.2)*dif * 2.0;        
    vec4 col = vec4( mix( vec3(1.0,0.95,0.8), vec3(0.4,0.3,0.35), den ), den );
    col.xyz *= lin;
    col.xyz = mix( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );
    // front to back blending    
    col.a *= 0.4;
    col.rgb *= col.a;
    return sum + col*(1.0-sum.a);
}

vec4 raymarchCloud(vec3 ro, vec3 rd, vec3 bgcol){
    vec4 sum = vec4(0.0);
    float t = 0.0;
    
    for(int i=0; i< 50; i++) { 
        vec3  pos = ro + t*rd - vec3(0.7, 5.0, 0.0);
        if( sum.a > 0.99 ) 
            break; 
        float den = cloudmap( pos ); 
        if( den>0.01 ) { 
            float dif =  clamp((den - cloudmap(pos+0.3*sundir))/0.6, 0.0, 1.0 );
            sum = integrate( sum, dif, den, bgcol, t ); 
        } 

         t += max(0.05,0.02*t);
    }
    
    return clamp( sum, 0.0, 1.0 );
}

void main(void)
{
    vec2 uv = (-resolution.xy + 2.0*gl_FragCoord.xy)/ resolution.y;
    vec3 ro = vec3(0.0, 0.1, 0.0);
    vec3 ta = vec3(0.0, 10.0, 1.0);
    mat3 ca = setCamera( ro, ta, 0.0 );
    
    // ray direction
    vec3 rd = ca * normalize( vec3(uv.xy, 2.0) );
    rd = normalize(rd);
    float sun = clamp( dot(sundir,rd), 0.0, 1.0 );
    float result = raymarch(ro, rd);
    vec3 color = mix(vec3(84.0, 69, 56.0)/255.0, vec3(134.0, 106.0, 65.0)/255.0, 
                     smoothstep(0.0, 1.0, -uv.y));

    vec3 hit = ro + result*rd;
    if (result > tmax){
        //draw moon
        float moon = smoothstep(0.0, 0.01, 0.18 - length(uv- vec2(0.0,0.4)));
        vec2 moonpos = uv - vec2(0.0,0.43);
        float r = noise11(atan(moonpos.x, moonpos.y)*7.0 + 2.0) * 0.008;
        float moonshade = smoothstep(0.0, 0.01, 0.18 + r - length(moonpos));
        moon = moon - min(moon,moonshade);    
        color = mix(color, mix(vec3(0.0),vec3(1.0), 2.5*length(moonpos) ), moon );
        
        color += 2.0*vec3(1.0,0.6,0.6)*pow( sun, 256.0 );    
        
        //draw clouds
        vec4 res = raymarchCloud( ro, rd, color );
           color = color*(1.0-res.w) + res.xyz;
    
    }
    else{
        //draw Monolith
        color = vec3(0.0);
    }
    
    color += 0.3*vec3(1.0,0.4,0.2)*pow( sun, 128.0 );   
    glFragColor = vec4(color.xyz, 1.0);
}
