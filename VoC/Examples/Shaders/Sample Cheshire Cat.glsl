#version 420

// original https://www.shadertoy.com/view/MdtSWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.141592654
mat2 m = mat2(0.6, 0.8, -0.6, 0.8);

float hash(float n)
{
    return fract(sin(n)*43758.5453123);
}

float noise(in vec2 v)
{
    vec2 p = floor(v);
    vec2 f = fract(v);
    
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + p.y*57.0;
    
    return mix( mix(hash(n), hash(n+1.0), f.x), mix(hash(n+57.0), hash(n+58.0), f.x), f.y);
}

float fbm(vec2 p)
{
    float f = 0.0;
    f += 0.5000*noise( p ); p*= m*2.02;
    f += 0.2500*noise( p ); p*= m*2.02;
    f += 0.1250*noise( p ); p*= m*2.01;
    f += 0.0625*noise( p );
    
    f /= 0.9375;
    
    return f;
}

vec4 uplip(vec2 q)
{

    vec4 col = vec4(0.0);
    float w = -0.15*abs(sin(q.x *4.0)) + 0.2;
    w *=(abs(exp(abs(q.x)*1.5)));
    
    q.y += 0.4;
    if(q.y < w && abs(q.x) < 0.8)
    {
        // up tooth
        float f= w+(-0.1*(abs(sin(q.x*60.0)))*(3.5-1.5*exp(abs(q.x))));

        if(q.y > f)
        {
            col = mix(col, vec4(1.0), 1.0);

        }
        col *= smoothstep(w, w-0.01, q.y);
        col *= smoothstep(f, f+0.03 , q.y);   

    }
    
    return col;
}

vec4 downlip(vec2 q)
{
    vec4 col = vec4(0.0);
    float dlip = (1.0-abs(cos(q.x)))*exp(abs(q.x*0.9))-0.5;

    q.y += 0.0;
    if(q.y > dlip )
    {
        float fd = dlip+(0.1*(abs(sin(q.x*70.0))))*(1.5-2.0*abs(q.x));

        if(q.y < fd)
        {
            col = mix(col, vec4(1.0), 1.0);
        }
        col *= smoothstep(dlip, dlip+0.01, q.y);
        col *= smoothstep(fd, fd-0.02, q.y);
    }
    
    return col;
}

vec4 mixcol(vec4 a, vec4 b, float f)
{
    if(a.a == 0.0)
        return b;
    else if(b.a == 0.0)
        return a;
    else
        return mix(a, b, f);
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0*q;
    
    vec4 ucol = uplip(p);
    vec4 dcol = downlip(p);
    dcol = mixcol(dcol, ucol, 1.0);
    p.x *= resolution.x/resolution.y;
    
    vec2 p1 = vec2(p.x+0.5, p.y-0.3);
    vec2 p2 = vec2(p.x-0.5, p.y-0.3);
    
    float r1 = sqrt(dot(p1, p1));
    float r2 = sqrt(dot(p2, p2));
 
    vec4 col = vec4(0.0);
    
    if(r1 < 0.25 || r2 < 0.25)
    {
        col =vec4(0.0, 0.8, 0.2, 1.0);
        float f = fbm(20.0*p1);
        col = mix(col, vec4(0.0, 0.3, 0.7, 1.0), f);
        
        float t = max(abs(sin(time))*0.8, 0.7);
        
        float e1 = -abs(cos(atan(p1.y, p1.x*2.0) + 0.0))*t*0.3 + 0.3;
        f = 1.0 - smoothstep(e1, e1+0.1, length(p1)*1.8);
        col = mix(col, vec4(0.0, 0.8, 0.4, 1.0), f);        
     
        float e2 = -abs(cos(atan(p2.y, p2.x*2.0) + 0.0))*t*0.3 + 0.3; 
        f = 1.0 - smoothstep(e2, e2+0.1, length(p2)*1.8);
        col = mix(col, vec4(0.0, 0.8, 0.4, 1.0), f);

        
        if(r1 < 0.3)
        {
            float a = atan(p1.y, p1.x);
            a += 0.05*fbm(20.0*p1);
            f = smoothstep(0.4, 1.0,fbm(vec2(r1*25.0, a*18.0)));
            col = mix(col, vec4(1.0), f);
            f = smoothstep(0.15, 0.25, r1);
            col *= 1.0 - f;
            
        }
        else if(r2 < 0.3)
        {
            float a = atan(p2.y, p2.x);
            a += 0.15*fbm(12.0*p2);
            f = smoothstep(0.4, 1.0, fbm(vec2(r2*25.0, a*18.0)));
            col = mix(col, vec4(1.0), f);
            f = smoothstep(0.15, 0.25, r2);
            col *= 1.0 - f;
        }
        
        col *= smoothstep(e1, e1+0.02, length(p1)*1.8);
        // left eye highlight
        f = 1.0-smoothstep(0.0, 0.1, length(p1 - vec2(0.1, 0.06)));
        col += vec4(f, f, f, 1.0);
        
        col *= smoothstep(e2, e2+0.02, length(p2)*1.8);
        // right eye highlight
        f = 1.0-smoothstep(0.0, 0.1, length(p2 - vec2(0.1, 0.06)));
        col += vec4(f, f, f, 1.0);
    }
    
    col = mixcol(col, dcol, 1.0);
    
    float anim = max(sin(time*0.3), 0.0);
    col = mix(col, vec4(0.0), anim);
    
    glFragColor = vec4(col);
}
