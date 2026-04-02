#version 420

// original https://www.shadertoy.com/view/Wd3SRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SHADERTOBER 27 Coat
// Poulet vert 29/10/2019
// thanks so much to iq for julia function (and others)

#define VOLUME 0.001
#define PI 3.14159

// iq
vec3 opRep(vec3 p, vec3 c)
{
     return mod(p+0.5*c,c)-0.5*c;
}

// iq
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

// iq
vec4 qsqr( in vec4 a ) // square a quaterion
{
    return vec4( a.x*a.x - a.y*a.y - a.z*a.z - a.w*a.w,
                 2.0*a.x*a.y,
                 2.0*a.x*a.z,
                 2.0*a.x*a.w );
}

// iq
vec4 qmul( in vec4 a, in vec4 b)
{
    return vec4(
        a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
        a.y * b.x + a.x * b.y + a.z * b.w - a.w * b.z, 
        a.z * b.x + a.x * b.z + a.w * b.y - a.y * b.w,
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y );

}

// iq
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

// Scene setup
vec2 map(vec3 p)
{
    // anim
    float time = time*.15;
    vec4 c =  vec4(-.5-sin(time)*.1,0.2,0.,0.); //http://paulbourke.net/fractals/quatjulia/
    
    p = opRep(p, vec3(2.0, 0.0, 0.0));
    p.y += sin(p.x*5.+time)*.3;
    
    
    float j1 = julia(p, c);
    
    vec2 scene = vec2(j1, 0.0);
    
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
            return vec2(float(i)/128., ray.y);
        }
        
        t += ray.x;
    }
    
    return vec2(-1.0, 0.0);
}

vec3 Render(vec3 ro, vec3 rd, vec2 uv)
{
    
    
    // map stuffs
    vec2 t = CastRay(ro, rd);
    vec3 pos = vec3(ro + rd * t.x);
    
    vec3 col = vec3(0.0);
    vec3 polyCol = palette(t.x+fract(time*.5), vec3(.5), vec3(1.0), vec3(1.0), vec3(0.67, 0.33, 0.0));
    
    if(t.x == -1.0)
    {
        col = vec3(length(uv)*.1);
    }
    else
    {    
        col = polyCol;
    }
    
    return col;
}

vec3 GetViewDir(vec2 uv, vec3 cp, vec3 ct)
{
    vec3 forward = normalize(ct - cp);
    vec3 right = normalize(cross(vec3(0.0, -1.0, 0.0), forward));
    vec3 up = normalize(cross(right, forward));
    
    return normalize(uv.x * right + uv.y * up + 2.0 * forward);
}

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    uv.x *= resolution.x/resolution.y;
    vec2 screenUV = gl_FragCoord.xy / resolution.xy;
    
    float time = time * .5;
    
    
    vec3 cp = vec3(2.0-time, 2.0, 2.0);
    vec3 ct = vec3(0.0-time, 0.0, 0.0);
    
    vec3 vd = GetViewDir(uv, cp, ct);
    
    vec3 col = Render(cp, vd, uv);
    
    col *= clamp(1.0-length(uv)+.5, 0.0, 1.0);
    
    col = sqrt(clamp(col, 0.0, 1.0));
    
    glFragColor = vec4(col,1.0);
}
