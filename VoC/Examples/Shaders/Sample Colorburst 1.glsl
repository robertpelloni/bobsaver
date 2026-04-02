#version 420

// original https://www.shadertoy.com/view/sl2XDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash( float n )
{
    return fract(sin(n)*758.5453)*2.;
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x); 
    //f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + p.z*800.0;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
            mix(mix( hash(n+800.0), hash(n+801.0),f.x), mix( hash(n+857.0), hash(n+858.0),f.x),f.y),f.z);
    return res;
}

float fbm(vec3 p)
{
    float f = 0.0;
    f += 0.50000*noise( p ); p = p*2.02+0.15;
    f -= 0.25000*noise( p ); p = p*2.03+0.15;
    f += 0.12500*noise( p ); p = p*2.01+0.15;
    f += 0.06250*noise( p ); p = p*2.04+0.15;
    f -= 0.03125*noise( p );
    return f/0.984375;
}

float cloud(vec3 p)
{
    p-=fbm(vec3(p.x,p.y,0.0)*0.5)*0.7;
    
    float a =0.0;
    a-=fbm(p*3.0)*2.2-1.1;
    if (a<0.0) a=0.0;
    a=a*a;
    return a;
}

mat2 rot( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

void main(void)
{
    float time = time;
    
    vec2 position = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    float ss = sin(length(position*3.0)+time*0.125);
    ss+=5.0;
    
    
       vec2 coord = ss*position;
        coord*=rot(ss*0.1+time*0.037);
    
    
    coord+=fbm(sin(vec3(coord*8.0,time*0.001)))*0.08;
    coord+=time*0.0171;
    float q = cloud((vec3(coord*1.0,0.222)));
    coord+=time*0.0171;
    q += cloud((vec3(coord*0.6,0.722)));
    coord+=time*0.0171;
    q += cloud(vec3(coord*0.3,.722));
    coord+=time*0.1171;
    q += cloud((vec3(coord*0.1,0.722)));
    
    
    float vv1 = sin(time+ss+coord.x)*0.3;
    float vv2 = sin(time*0.9+ss+coord.y)*0.2;

vec3    col = vec3(1.7-vv2,1.7,1.7+vv1) + vec3(q*vec3(0.7+vv1,0.5,0.3+vv2*1.15));
    col = pow(col,vec3(2.2));
    
    float dd = length(col*.48)+vv1;
    
    float nn = 0.5+sin(ss*.7+position.x*.41+time*0.9)*0.5;
    
    col = mix(col,vec3(dd),nn);
    
    glFragColor = vec4( col*0.08, 1.0 );
}
