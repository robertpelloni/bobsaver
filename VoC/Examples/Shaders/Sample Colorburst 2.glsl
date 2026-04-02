#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ftSSWw

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

vec3 hash33(vec3 p)
{
    const float UIF = (1.0/ float(0xffffffffU));
    const uvec3 UI3 = uvec3(1597334673U, 3812015801U, 2798796415U);
    uvec3 q = uvec3(ivec3(p)) * UI3;
    q = (q.x ^ q.y ^ q.z)*UI3;
    return vec3(q) * UIF;
}

// 3D Voronoi- (IQ)
float voronoi(vec3 p){

    vec3 b, r, g = floor(p);
    p = fract(p);
    float d = 1.; 
    for(int j = -1; j <= 1; j++)
    {
        for(int i = -1; i <= 1; i++)
        {
            b = vec3(i, j, -1);
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
            b.z = 0.0;
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
            b.z = 1.;
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
        }
    }
    return d;
}

// fbm layer
float noiseLayers(in vec3 p) {

    vec3 pp = vec3(0., 0., p.z + time*.09);
    float t = 0.;
    float s = 0.;
    float amp = 1.;
    for (int i = 0; i < 5; i++)
    {
        t += voronoi(p + pp) * amp;
        p *= 2.;
        pp *= 1.5;
        s += amp;
        amp *= .5;
    }
    return t/s;
}

vec3 n2 ()
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
        float dd = length(uv*uv)*.025;
    
    vec3 rd = vec3(uv.x, uv.y, 1.0);
    
    float rip = 0.5+sin(length(uv)*20.0+time)*0.5;
    rip = pow(rip*.38,4.15);
    rd.z=1.0+rip*1.15;// apply a subtle ripple
    rd = normalize(rd);
    //rd.xy *= rot(dd-time*.025);
    rd*=2.0;
    
    float c = noiseLayers(rd*1.85);
    float oc = c;
    c = max(c + dot(hash33(rd)*2. - 1., vec3(.006)), 0.);
    c = pow(c*1.55,2.5);    
    vec3 col =  vec3(.55,0.85,.25);
    vec3 col2 =  vec3(1.4,1.4,1.4)*5.0;
    float pulse2 = voronoi(vec3((rd.xy*1.5),time*.255));
    float pulse = pow(oc*1.35,4.0);
    col = mix(col,col2,pulse*pulse2)*c;
    return col;

}

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
    
    float nn = 0.5+sin(ss*2.7+position.x*2.41+time*0.9)*0.5;
    
    vec3 col2 = n2()*12.0;
    col2+=col;
    col = mix(col,col2,nn);
    
    glFragColor = vec4( col*0.08, 1.0 );
}
