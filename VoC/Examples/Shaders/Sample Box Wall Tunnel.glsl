#version 420

// original https://www.shadertoy.com/view/ttSGzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(A) mat2(cos(A),-sin(A),sin(A),cos(A))

#define ID_LIGHT 0
#define ID_MENGER 1
#define ID_TUNNEL 2

float smoothSquare(in float x) { return smoothstep(.3, .7, pow(sin(x),2.)); }

float rand( in vec2 co )
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 path(float d)
{
    return vec3(cos(d*0.3)*2.0,sin(d*0.3)*2.0,d);
}

float wave(float a)
{
    
    float b = min(mod(-time*2.0+a*0.1,10.0),3.14);
    
    return max(sin(b),0.0)*2.0;
}

vec4 trace(vec3 ro, vec3 rd, float far)
{
    
    
    
    float d = 0.0;
    float d2 = 9999.0;
    vec3 fp = floor(ro);
    vec3 lp = ro-fp;
    vec3 ird = 1.0/abs(rd);
    vec3 srd = sign(rd);
    vec3 n;
    
    vec3 lens = abs(step(0.0,rd)-lp)*ird;
    
    for (int i = 0; i < 1000; i++)
    {
        
        vec3 g = path(fp.z);
        
        vec3 h = g-fp;
        
        float j = wave(fp.z);
        
        //towers pointing in negative x,y,z direction (the ceiling and two walls)
        vec2 a = vec2( g.x+4.0-j+(2.0-j)*0.8*smoothSquare(.25*time + 3.14*rand(fp.yz-0.1)),
                       g.y+4.0-j+(2.0-j)*0.8*smoothSquare(.25*time + 3.14*rand(fp.xz-0.2)));
        
        //towers pointing in positive x,y,z direction (the floor and two walls)
        vec2 b = vec2( g.x-4.0+j-(2.0-j)*0.8*smoothSquare(.25*time + 3.14*rand(fp.yz-0.4)),
                       g.y-4.0+j-(2.0-j)*0.8*smoothSquare(.25*time + 3.14*rand(fp.xz-0.5)));
        
        vec2 c = (a-b)*0.5;
        vec2 e = b+c;
        
        vec2 p = (ro.xy+rd.xy*d)-e;
        
        vec2 f = (c-srd.xy*p)*ird.xy*step(abs(p),vec2(c));
        
        vec2 mask2 = f.x < f.y ? vec2(1,0) : vec2(0,1);
        
        float d2 = dot(mask2,f);
        float d3 = d;
        
        vec3 mask;
        if (lens.x < min(lens.y,lens.z)) {
            mask = vec3(1,0,0);
        } else if (lens.y < lens.z) {
            mask = vec3(0,1,0);
        } else {
            mask = vec3(0,0,1);
        }
        
        d = dot(mask,lens);
        
        if (d > min(d2+d3, far)) {
            d = d2+d3;
            if (d2 > 0.0) n = vec3(mask2,0)*srd;
            break;
        }
        
        n = mask*srd;
        
        fp += n;
        
        lens += mask*ird;
    }
    
    
    return vec4(d, -n);
}

float sphere( in vec3 ro, in vec3 rd, float far)
{
    
    float b = dot( ro, rd );
    float c = dot( ro, ro )-0.03;
    float h = b*b - c;
    if( h<0.0 ) return far;
    return -b-sqrt( h );
}

float mid(vec3 p) {
    p = max(p,p.yzx);
    return min(min(p.x,p.y),p.z);
}

//box intersection from iq
//https://www.shadertoy.com/view/ld23DV
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad, float far) 
{
    // ray-box intersection in box space
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    
    float tN = max(max( t1.x, t1.y ), t1.z);
    float tF = min(min( t2.x, t2.y ), t2.z);

    return vec2(max(tN,0.0), min(tF,far));
}

vec4 mengersponge(vec3 ro, vec3 rd, float size, float far) {
    
    vec3 ird = 1.0/abs(rd);
    
    vec2 d = iBox(ro, rd, vec3(size), far);
    
    vec3 c = vec3(0);
    
    for (int i = 0; i < 16; i++) {
        if (d.x > d.y) return vec4(far,0,0,0);
        vec3 p = ro+rd*d.x;
        
        float l = 0.0;
        float s = size;
        for (int j = 0; j < 4; j++) {
            vec3 a = mod(p,s*2.0)-s;
            a = s/1.5-a*sign(rd);
            vec3 dists = a*ird*step(a,vec3(s*2.0/1.5));
            
            float b = mid(dists);
            
            if (b > l) {
                l = b;
                c = dists;
            }
            
            s /= 3.0;
        }
        
        if (l == 0.0) break;
        
        d.x += l;
    }
    
    vec3 n;
    if (c == vec3(0)) {
        vec3 p = abs(ro+rd*d.x);
        n = vec3(equal(p,vec3(max(max(p.x,p.y),p.z))));
    } else {
        n = vec3(equal(c,vec3(mid(c))));
    }
    
    return vec4(d.x,-sign(rd)*n);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;
    
    vec3 ro = path(time*2.0);
    vec3 rd = normalize(vec3(uv,1));
    
    //if (length(mouse*resolution.xy.xy/resolution.y) > 0.1)
    //{
    //    rd.yz *= rot(-mouse*resolution.xy.y/resolution.y*3.14+3.14*0.5);
    //    rd.xz *= rot(-mouse*resolution.xy.x/resolution.x*6.28+3.14);
    //}
    //else
    //{
        vec3 lookatz = normalize(path(time*2.0+1.0)-ro);
        vec3 lookatx = normalize(cross(vec3(0,1,0),lookatz));
        vec3 lookaty = cross(lookatz,lookatx);
        
        rd = lookatx*rd.x+lookaty*rd.y+lookatz*rd.z;
    //}
    
    vec3 light = path(time*2.0+5.0);
    vec3 menger = light+vec3(sin(time+0.8),cos(time*0.4),sin(time/3.14));
    
    int id = ID_LIGHT;
    float d = sphere(ro-light,rd,1000.0);
    vec3 n = vec3(0);
    
    vec4 l = mengersponge(ro-menger, rd, 1.0, d);
    
    if (l.x < d)
    {
        id = ID_MENGER;
        d = l.x;
        n = l.yzw;
    }
    
    l = trace(ro,rd, d);
    
    if (l.x < d)
    {
        id = ID_TUNNEL;
        n = l.yzw;
        d = l.x;
    }
    
    if (id == ID_LIGHT)
    {
        glFragColor = vec4(1);
        return;
    }
    
    vec3 p = ro+rd*d;
    
    vec3 lightn = p-light;
    float lightd = length(lightn);
    lightn /= lightd;
    
    if (id == ID_TUNNEL)
    {
        glFragColor = vec4(l.yzw*0.2+sin(p)*0.3+0.5,1.0);
    }
    else if (id == ID_MENGER)
    {
        glFragColor = vec4(0.8,0.2,0.4,1);
    }
    float diff = -dot(n,lightn);
    
    vec3 shadowro = p-lightn*0.001;
    vec3 shadowrd = -lightn;
    
    if (mengersponge(shadowro-menger, shadowrd, 1.0,trace(shadowro,shadowrd,lightd).x).x < lightd-0.001) {
        diff *= 0.0;
    }
    
    
    diff = max(diff,0.1);
    
    glFragColor *= diff;
    
    glFragColor = sqrt(glFragColor);
}
