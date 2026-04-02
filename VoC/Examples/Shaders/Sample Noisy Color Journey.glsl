#version 420

// original https://www.shadertoy.com/view/ss2GW3

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
    
     float x = (_uv.x + 4.0 ) * (_uv.y + 4.0 ) * (time * 10.0);
     vec4 grain = vec4(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) *  amount;
     return grain.xyz;
    
}

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);

    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

const mat2 mtx = mat2( 0.80,  0.60, -0.60,  0.80 );

float fbm( vec2 p )
{
    float f = 0.0;
/*
    vec2 p1 = vec2(p.x*.6,p.y*.6 + time*.12);
    f += 0.500000*noise( p1); p1 = mtx*p1*3.03;
    
   
    vec2 p2 = vec2(p.x*1.6 + time*.3 ,p.y*2.6 );
    f += 0.300000*noise( p2); 
    
    
    vec2 p3 = vec2(p.x*3.6 - time*.6 ,p.y*6.6 );
    f += 0.200000*noise( p3);
    
 vec2 p4 = vec2(p.x*13.6 - time*.6 ,p.y*16.6 );
    f += 0.200000*noise( p4);
    */
    
    
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

    float _x = mouse.x;

    vec2 uv = gl_FragCoord.xy/resolution.y;
    
    //uv.x = sin(uv.x*5.);
    
    uv.x += resolution.y/resolution.x;
    
    uv = rot(uv,time*.03);
    
    float shade = pattern(uv);
    
    
    
    vec3 col = vec3(
        sin(shade*.91+ time*.01)*1.75+.5 ,
        cos(shade*3.+ time*.13)*.75+.5 ,
        cos(shade*13.+ time*.13)*.5+.6 
            //shade*.7+.4
    );
    
    col = hsv2rgb(col);
    
    col += returnGrain(uv,9.);
    
    glFragColor = vec4( col, 1.0 );

}

 
