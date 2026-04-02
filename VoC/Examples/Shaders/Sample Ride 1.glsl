#version 420

// original https://www.shadertoy.com/view/tdcSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SHADERTOBER 28 Ride
// Poulet vert 30-10-2019
// second shader based on Julia function by iq
// thanks leon <3

#define VOLUME 0.001
#define PI 3.14159

vec3 opRep(vec3 p, vec3 c)
{
     return mod(p+0.5*c,c)-0.5*c;
}

vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec2 opU2( vec2 d1, vec2 d2 )
{
    return (d1.x < d2.x) ? d1 : d2;
}

vec4 qsqr( in vec4 a ) // square a quaterion
{
    return vec4( a.x*a.x - a.y*a.y - a.z*a.z - a.w*a.w,
                 2.0*a.x*a.y,
                 2.0*a.x*a.z,
                 2.0*a.x*a.w );
}

vec4 qmul( in vec4 a, in vec4 b)
{
    return vec4(
        a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
        a.y * b.x + a.x * b.y + a.z * b.w - a.w * b.z, 
        a.z * b.x + a.x * b.z + a.w * b.y - a.y * b.w,
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y );

}

vec4 qconj( in vec4 a )
{
    return vec4( a.x, -a.yzw );
}

// iq Julia src : https://www.shadertoy.com/view/MsfGRr
const int numIterations = 11;
float julia(vec3 p, vec4 c)
{
    vec4 z = vec4(p,0.0);
    
    float md2 = 1.0;
    float mz2 = dot(z,z);

    float n = 1.0;
    for( int i=0; i<numIterations; i++ )
    {
        md2 *= mz2;
        z = qsqr(z) + c;  
        mz2 = dot(z,z);
        if(mz2>4.0) break;
        n += 1.0;
    }
    
    return 0.1*sqrt(mz2/md2)*exp2(-n)*log(mz2);
}

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

// Scene setup
vec2 map(vec3 p)
{
    // ground
    vec3 gp = p + vec3(0.0);
    gp.y += sin(p.z+time*5.)*sin(p.x*5.)*.1;
    float d = gp.y;
    
    // sun
    vec3 cp = p + vec3(0.0, -2.0, -30.0);
    float c = sdSphere(cp,  5.);
    
    // moutain
    vec3 mp = p + vec3(0.0, -0.5, -20.0);
    mp = opRep(mp, vec3(1.0, 0.0, 0.0));
    mp.y += sin(p.x*4.)*.2;
    mp.y += abs(p.x)*.2;
    float m = sdSphere(mp, 1.5);
    
    // julia
    vec3 jp = p + vec3(sin(time), -2.0, cos(time)*2.0);
    float j = julia(jp, vec4(.5+abs(sin(p.z+time)), p.y, .5, p.z));
    
    // julia 2
    jp = p + vec3(sin(time+2.0), -2.0, cos(time)*2.0+1.0);
    j = min(j, julia(jp, vec4(.5+abs(sin(p.z+time)), p.y, .5, p.x)));
    
    
    // materials
    vec2 scene = vec2(d, 0.0);
    scene = opU2(scene, vec2(c, 1.0));
    scene = opU2(scene, vec2(m, 2.0));
    scene = opU2(scene, vec2(j, 3.0));
    
    return scene; 
}

vec2 CastRay(vec3 ro, vec3 rd)
{
    float t = 0.0;
    
    for(int i=0 ; i<128 ; i++)
    {
        vec2 ray = map(ro + rd * t);
        
        if(ray.x < (0.0001*t))
        {
            return vec2(t, ray.y);
        }
        
        t += ray.x;
    }
    
    return vec2(-1.0, 0.0);
}

vec3 GetNormal (vec3 p)
{
    float c = map(p).x;
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(map(p+e.xyy).x, map(p+e.yxy).x, map(p+e.yyx).x) - c);
}

vec3 Render(vec3 ro, vec3 rd, vec2 uv, float time)
{
    
    
    // map stuffs
    vec2 t = CastRay(ro, rd);
    vec3 pos = vec3(ro + rd * t.x);
    
    vec3 col = vec3(0.0);
    vec3 polyCol = palette(fract(time), vec3(.5), vec3(1.0), vec3(1.0), vec3(0.67, 0.33, 0.0));
    
    vec3 nor = GetNormal(pos);
    vec3 light = vec3(0.0, 1.0, -5.0);
    float l = clamp(dot(nor, light), 0.0, 1.0);
    
    if(t.x == -1.0)
    {
        vec3 ramp = mix(vec3(1.0, 0.0, 0.5), vec3(0.0,  0.0, 1.0), max(uv.y, 0.0));
        ramp *= ramp;
        ramp *= uv.y;
        ramp = clamp(ramp, 0.0, 1.0);
        ramp *= abs(uv.y)*-1.+.5;
        
        col = ramp;
    }
    else
    {   
        if(t.y==0.0) // ground grid
        {
            vec2 groundPos = pos.xz;
            groundPos.y += time;
            
            // first version
            //float grid = clamp(step(fract(groundPos.x*1.), .05) + step(fract(groundPos.y*1.), .05), 0.0, 1.0);
            
            // edit thanks to ocb
            float grid = max(.1/(abs(fract(groundPos.x)-.5)+.1) + .1/(abs(fract(groundPos.y)-.5)+.1)-.5,0.);
            
            col = vec3(0.0, 0.0, 1.0) * grid;
            col *= clamp(-pos.z*.01+.1, 0.0, 1.0)*10.;
        }
        else if(t.y==1.0) // sun
        {
            col = mix(vec3(1.0, .0, .3), vec3(0.0, .5, 1.0), uv.y*3.0-.3);
        }
        else if(t.y==2.0) // black
        {
            col = vec3(0.0);
        }
        else if(t.y==3.0) // shape
        {
            col = vec3(1.0, .0, .3) * l + fract(time*5.0);
        }
    }
    
    return col;
}

vec3 GetViewDir(vec2 uv, vec3 cp, vec3 ct)
{
    vec3 forward = normalize(ct - cp);
    vec3 right = normalize(cross(vec3(sin(time)*.2, -1.0, 0.0), forward));
    vec3 up = normalize(cross(right, forward));
    
    return normalize(uv.x * right + uv.y * up + 2.0 * forward);
}

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    uv.x *= resolution.x/resolution.y;
    vec2 screenUV = gl_FragCoord.xy / resolution.xy;
    
    float time = time * 5.0;
    
    
    vec3 cp = vec3(sin(time)*.1, 1.0+sin(time)*.2, -5.0);
    vec3 ct = vec3(0.0, 1.0, 0.0);
    
    vec3 vd = GetViewDir(uv, cp, ct);
    
    vec3 col = Render(cp, vd, uv, time);
    
    col.b -= uv.y*.2;
    col *= clamp(1.0-length(uv*.75), 0.0, 1.0);
    
    
    
    col = sqrt(clamp(col, 0.0, 1.0));
    
    glFragColor = vec4(col,1.0);
}
