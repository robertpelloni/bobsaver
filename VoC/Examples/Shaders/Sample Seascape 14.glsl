#version 420

// original https://www.shadertoy.com/view/ts2yzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SC (250.0)

float random(in vec2 uv)
{
    return fract(sin(dot(uv.xy, 
                         vec2(12.9898, 78.233))) * 
                 43758.5453123);
}

float noise(in vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3. - 2. * f);
    
    float lb = random(i + vec2(0., 0.));
    float rb = random(i + vec2(1., 0.));
    float lt = random(i + vec2(0., 1.));
    float rt = random(i + vec2(1., 1.));
    
    return mix(mix(lb, rb, f.x), 
               mix(lt, rt, f.x), f.y);
}

float seaOctave(vec2 uv, float choppy) 
{    
    float noise = noise(uv);
    float x = cos(noise);
    float y = sin(noise);
       return pow(pow(abs(x * y), 0.65), choppy);
}

float f(vec3 p) 
{
    vec2 uv = p.xz * vec2(0.85, 1.0); 
    
    float freq      = 1.;
    float amp    = .5;  
    float choppy = 7.;
    
    float gSeaCurrentTime = time;
    
    float d = 0.0;
    float h = 0.0;    
    for(int i = 0; i < 20; ++i) 
    {        
        d =  seaOctave((uv + gSeaCurrentTime) * freq, choppy);
        d += seaOctave((uv - gSeaCurrentTime) * freq, choppy); 
        h += d * amp;
    
        freq *= 2.; 
        amp  *= .2;
    
        uv *= mat2(1.6, 1.2, -1.2, 1.6);
    }
    return h;
}

vec3 getNormal(vec3 p, float t)
{ 
    vec3 eps=vec3(.001 * t, .0, .0);
    vec3 n=vec3(f(p - eps.xyy) - f(p + eps.xyy),
                2. * eps.x,
                f(p - eps.yyx) - f(p + eps.yyx));
  
       //return vec3(0., 1., 0.);
    return normalize(n);
    
}

vec3 sun(vec3 rd, vec3 lightDir)
{
    vec3 col = vec3(0.);
    
    float sundot = clamp(dot(rd, lightDir), 0.0, 1.0);
    col += 0.25*vec3(1.0,0.7,0.4)*pow( sundot,5.0 );
    col += 0.25*vec3(1.0,0.8,0.6)*pow( sundot,64.0 );
       col += 0.2*vec3(1.0,0.8,0.6)*pow( sundot,512.0 );
    
    return col;
}

vec3 sky(vec3 rd, vec3 lightDir)
{
    vec3 col = vec3(0.3,0.5,0.85) - rd.y*rd.y*0.5;
    col = mix( col, 0.85*vec3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
    
    // horizon
    col = mix( col, 0.68*vec3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
    
    return col;
}

float fresnel(vec3 N, vec3 V)
{
    float F0 = 0.04;
    
    return F0 + (1. - F0) * pow(1. - dot(V, N), 5.);
}

vec3 lighting(vec3 N, vec3 L, vec3 V)
{
    vec3 R = normalize(reflect(-L, N));
    
    float spec = max(dot(R, V), 0.);
    spec = pow(spec, 60.);
    spec = clamp(spec, 0., 1.);
    
    float fresnel = fresnel(N, V);
    
    vec3 reflected = sky(reflect(-V, N), L);
    vec3 refracted = vec3(.059, .059, .235);    // ocean color
    
    vec3 col = mix(refracted, reflected, fresnel);
    col += vec3(spec) ;
    
    return clamp(col, 0., 1.);
}

float rayMarching(in vec3 ro, in vec3 rd, float tMin, float tMax)
{
    if (rd.y > .0)
    {
        return tMax + .1;
    }
    else
    {
        return abs(ro.y / rd.y);
    }
}

mat3 lookAt(vec3 origin, vec3 target, float roll)
{
    vec3 rr = vec3(sin(roll), cos(roll), 0.0);
    vec3 ww = normalize(target - origin);
    vec3 uu = normalize(cross(ww, rr));
    vec3 vv = normalize(cross(uu, ww));

    return mat3(uu, vv, ww);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    vec2 mo = mouse*resolution.xy.xy/resolution.xy;
    
    vec3 camPos = vec3(0., 1., 0.);
    vec3 camTarget = vec3(4, 0, 0);
    
    mat3 mat = lookAt(camPos, camTarget, 0.0);
    
    vec3 ro = camPos;
    vec3 rd = normalize(mat * vec3(uv.xy, 1.0));
    
    float tMin = .1;
    float tMax = 100.;
    float t = rayMarching(ro, rd, tMin, tMax);
    
    vec3 col = vec3(0.);
    
    vec3 lightDir = normalize(vec3(10., 1, 0.));
    
    if (rd.y > 0.)
    {
        // sky
        col = sky(rd, lightDir);
        col += sun(rd, lightDir);
    }
    else
    {
        // Ocean lighting
        vec3 p = ro + rd * t;
        vec3 normal = getNormal(p, t); 
        
        col = lighting(normal, lightDir, -rd);
        
    }
    
    glFragColor = vec4(col,1.0);
}
