#version 420

// original https://www.shadertoy.com/view/wtGXRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ShaderDojo045 By Anton
// cc by

// source inspiration : twitter.com/antonkudin/status/1231193061738328069
// by @antonkudin

#define fGlobalTime (time * .4)
#define PI 3.14159
#define TAU  6.28319

// Hashes from https://www.shadertoy.com/view/4djSRW
//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

mat2 rot(float a)
{
  float ca = cos(a);float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float fbm(vec2 p)
{
    mat2 m = mat2(.8,-.6,.6,.8);
    float acc = 0.;
    p *= -m * m * .5;

    // Accumulating a noise with higher and higher frequencies but smaller and smaller amlitudes.
    for(float i = 1.; i < 7.; ++i)
    {
        p += vec2(i * 1251.675, i * 6568.457) + vec2(-fGlobalTime * .3);
        p *= m;
        float octave = (sin(p.x * i) + cos(p.y * i)) * 1./(i * .5); 
        acc += octave;
    }

    return acc;
}

// Distance function of the sea.
float map(vec3 p)
{
    // Adding a multi octave noise.
    p.y -= fbm(p.xz) * .1;
    
    // Faking an horizon.
    p.y += pow(length(p.xz) * .05, 3.);
    
    return p.y;
}

vec3 normal(vec3 p)
{
    // Intentionally skewing the normals so the sea reflection appear smoother than the sea.
    vec2 e = vec2(1.2,.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

void ray(inout vec3 cp,in vec3 rd,out float st,out float cd,out float d)
{
    for(st = 0.; st < 1.; st += 1. / 256.)
    {
        cd = map(cp);
        if(abs(cd) < .01 || cd > 10.)
        {
           break;
        }
        
        d += cd;
        cp += rd * cd ;
    }
}

vec3 lookAt(vec3 ro, vec3 ta, vec2 uv)
{
    vec3 fd = normalize(ta - ro);
    vec3 up = cross(fd, vec3(1.,0.,0.));
       vec3 ri = cross(fd, up);
    
   return normalize(fd - ri * uv.x + up * uv.y); 
}

vec3 blueSky = vec3(.0001, .00002, .005) ;
vec3 sunCol = vec3(.0075,.0025,.25);
vec3 darkBlue = vec3(.00005,.00001,.00015);
vec3 riseUp = vec3(.15,.12,.3);
vec3 starCol = vec3(.033,.005,.5) * 20.;
vec3 seaCol = vec3(.004,.012,.032);

vec3 sunDir = normalize(vec3(0.,.4,1.));
float sunRadius = .01;

float rotSpeed = .0004;
float starWidth = .005;

vec3 skyCol(vec3 rd)
{
    float sky = dot(rd, sunDir);
    
    vec3 up = cross(-sunDir, vec3(0.,1.,0.));
    vec3 ri = cross(up, -sunDir);
    vec2 dp = vec2(dot(rd, ri), dot(rd,up));
    
    float sunRim = sky - 1. + sunRadius;
    float circle = 1. - smoothstep(.0005,.0014, abs(sunRim));
    
    vec3 col = sunCol * pow(sky, 2.) * step(sky-1., -sunRadius);
    circle *= circle;
    sky = pow(sky, 19.);
    sky = clamp(sky *2.2, 0.,1.);
    col = mix(col, blueSky, 1. - sky);
    float t = -.3;
    float d = .45;
    col = mix(riseUp, col, smoothstep(t, t + d, rd.y));
    
    col += circle + pow((1. - abs(sunRim)), 700.);
    col += sunCol* (pow((1. - abs(sunRim)), 256.) +  circle) * 10. * smoothstep(-0.8,3.,sunRim);
    
    return col;
}

vec3 skyStars(vec3 rd)
{
    
    float sky = dot(rd, sunDir);
    
    
    vec3 up = cross(-sunDir, vec3(0.,1.,0.));
    vec3 ri = cross(up, -sunDir);
    vec2 dp = vec2(dot(rd, ri), dot(rd,up));
    float a = atan(-dp.y, dp.x) / TAU + .5;

    float starSpace = length(vec2(dot(up,rd),dot(ri,rd)));
    float starId = floor(starSpace / starWidth);
       float starY = abs(mod(starSpace, starWidth)/starWidth - .5) * 2.;
    float hashedId = hash11(starId);
    a = fract(a + hashedId * 100. + (time * starId * (1. + hashedId * .2)) * -rotSpeed);
    float star = length(vec2((max(a- .5,.0)) / starWidth, starY));
    star = (1.-smoothstep(.0,1.5,star)) * smoothstep(.05,.25,a) * (hashedId * .2 + .8);
    
    float circle = 1. - step(.0025,abs(sky - 1. + sunRadius));
    
    circle *= circle;
    star *= max(step(sky -1., -sunRadius) - circle, 0.);
    
    return starCol * pow(star, 16.);
    
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5)/resolution.y;
    vec3 col = vec3(0.);
    
    float len = length(uv - vec2(0.,.2));
    float a = (atan(uv.y, uv.x) + PI) / TAU;
    
    
    starWidth = 4. / resolution.y;
    float bobAmp = .5;
    float bobTime = time * .125;
    vec3 cp = vec3(0. + cos(bobTime) * bobAmp,1.5 + sin(bobTime * 2.) * bobAmp,-8. + sin(bobTime * .33));
    vec3 ta = vec3(0.,2.5,0.);
    vec3 rd = lookAt(cp,ta,uv);
    
    float st, cd, dist;
    ray(cp, rd, st, cd, dist);
    
    col = skyCol(rd) + skyStars(rd);
        
    if(cd < .01)
    {
        vec3 norm = normal(cp);
        float si = clamp(dot(norm, -rd), 0.,1.);
        
        float skyUpI = clamp(dot(norm, vec3(0.,1.,0.)),0.,1.);
        col = mix(seaCol, darkBlue, pow(skyUpI, 3.));
        
        vec3 refl = reflect(rd, norm);
        
        float skyFdI = dot(refl, normalize(vec3(0.,1.,1.)));
        
        vec3 skyFdCol = skyCol(refl);
        col += skyFdCol * pow(skyFdI, 16.) * .75;
    }
    
    col = pow(col, vec3(.4545));
    
    glFragColor = vec4(col,1.0);
}
