#version 420

// original https://www.shadertoy.com/view/sdB3Wt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*licenced under love, peace and happyness ✌️ */

 //generic rotation formula
vec2 rot(vec2 uv,float a){
    return vec2(uv.x*cos(a)-uv.y*sin(a),uv.y*cos(a)+uv.x*sin(a));
}

vec3 returnGrain(vec2 _uv, float amount){
    
     float x = (_uv.x + 4.0 ) * (_uv.y + 4.0 ) * ( 1110.0);
     vec4 grain = vec4(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) *  amount;
     return grain.xyz;
    
}

vec3 hash3( float n ) { return fract(sin(vec3(n,n+1.0,n+2.0))*43758.5453123); }

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

const mat2 mtx = mat2( 0.80,  0.60, -0.60,  0.80 );

float fbm( vec2 p )
{
    float f = 0.0;
 
    
    for(int i=0;i<11; i++){

    vec2 p1 = vec2(p.x*.4*float(i),p.y*.4*float(i));
        
    p1.x *=    noise(p1*.5+time*.1)*.4;
    p1.y *=    noise(p*.5-time*.1)*.4;
        
        f += 0.8*noise(p1); p1 = mtx*p1*3.03;    
        
    
    }
    

    return f;
}

float pattern( in vec2 p )
{
    return fbm( p + fbm( p*2.3 + fbm( p*.33 ) ) );
}

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void)
{

    
    vec2 q = gl_FragCoord.xy / resolution.xy;
    float _x = .65 + sin(time*.1)*.1 ;//mouse*resolution.xy.x/resolution.x;

    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv.x += resolution.y/resolution.x;
    
    
    
    
    uv.x = sin(uv.x*15.)*.5+.5;
    uv.y *= 5.;
    
    uv.y -= time*.1;
    
  // uv *=5.;
   
     vec2 ouv = uv;
     
    
    float shade = pattern(uv);
    
    shade = sin(noise(uv)*3.14);
    
    //shade += sin(uv.x)*6.*_x; // osc
    
     shade += sin(uv.y*.4+.1)*6.*_x;
    
    shade = floor(shade*5.)*255. + shade*.2;
    
   
    
    vec3 col = vec3(
        sin(shade*.91+ time*.01)*1.75+.5 ,
        cos(shade*3.+ time*.13)*.75+.5 ,
        cos(shade*13.+ time*.13)*.5+.6 
            //shade*.7+.4
    );
    
    
    col = hsv2rgb(col);
    
     
     col += returnGrain(ouv,6.);
     
     
     
      // vignetting    
   col *= 0.3 + .7*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.15);
    
    
    glFragColor = vec4( col, 1.0 );

}

 
