#version 420

// original https://www.shadertoy.com/view/WdfyRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433

float sq(vec3 x)
{
    return dot(x, x);
}
float sq(vec2 x)
{
    return dot(x, x);
}
float sq(float x)
{
    return x*x;
}
int sq(int x)
{
    return x*x;
}

vec2 sic(float t)
{
    return vec2(cos(t), sin(t));
}

struct TorusKnotParameters
{
    float kp;
    float kq;
    float r1;
    float r2;
    float r3;
};

vec3 torusKnot(float t, TorusKnotParameters tkp)
{
    vec2 sicXY = sic(tkp.kp * t);
    vec2 sicRZ = tkp.r2 * sic(tkp.kq * t);
    
    return vec3((sicRZ.x + tkp.r1)*sicXY, sicRZ.y);
}
vec3 torusKnotDerivative(float t, TorusKnotParameters tkp)
{
    vec2 sicXY = sic(tkp.kp * t);
    vec2 sicRZ = tkp.r2 * sic(tkp.kq * t);
    
    vec2 dSicXY = tkp.kp * vec2(-1, 1) * sicXY.yx;
    vec2 dSicRZ = tkp.kq * vec2(-1, 1) * sicRZ.yx;
    
    return vec3(dSicRZ.x*sicXY + dSicXY*(sicRZ.x + tkp.r1), dSicRZ.y);
}

float torusKnotSqDistance(float t, vec3 p, TorusKnotParameters tkp)
{
    return sq(torusKnot(t, tkp) - p);
}
float torusKnotSqDistanceDerivative(float t, vec3 p, TorusKnotParameters tkp)
{
    return 2.*dot(torusKnot(t, tkp) - p, torusKnotDerivative(t, tkp));
}

float minimizeDistance(float t, vec3 p, TorusKnotParameters tkp)
{
    float lerningRate = 0.01/max(tkp.kq,tkp.kp);
    const int maxIterations = 30;
    
    for(int i = 0; i < maxIterations; i++)
    {
        float dt = torusKnotSqDistanceDerivative(t, p, tkp);
        
        if(abs(dt) < 0.001)
            break;
        
        t -= lerningRate*dt;
    }
    
    return t;
}

struct Ray
{
  vec3 ro;
  vec3 rd;
};

float torusKnotLineSqDistance(float t, Ray ray, TorusKnotParameters tkp)
{
    //|d| = 1
    
    //a^2 = c^2 - b^2
    //a^2 = c^2 - (b/c * c)^2
    //a^2 = c^2 - (cos() * c)^2
    
    return torusKnotSqDistance(t, ray.ro, tkp) - sq(dot(torusKnot(t, tkp) - ray.ro, ray.rd));
}
float torusKnotLineSqDistanceDerivative(float t, Ray ray, TorusKnotParameters tkp)
{
    //return torusKnotSqDistanceDerivative(t, ray.ro, tkp) - 2.*dot(torusKnot(t, tkp) - ray.ro, ray.rd)*dot(torusKnotDerivative(t, tkp), ray.rd);
    //  ⇓
    //return 2.*dot(torusKnot(t, tkp) - ray.ro, torusKnotDerivative(t, tkp)) - 2.*dot(torusKnot(t, tkp) - ray.ro, ray.rd)*dot(torusKnotDerivative(t, tkp), ray.rd);
    //  ⇓
    
    vec3 tk = torusKnot(t, tkp);
    vec3 tkd = torusKnotDerivative(t, tkp);
        
    //return 2.*dot(tk - ro, tkd) - 2.*dot(tk - ro, rd)*dot(tkd, rd);
    //  ⇓
    //return 2.*(dot(tk - ro, tkd) - rdot(tk - ro, rd)*dot(tkd, rd));
    //  ⇓
    //return 2.*(dot(tk - ro, tkd) - rdot(tk - ro, rd*dot(tkd, rd)));
    //  ⇓
    return 2.*(dot(tk - ray.ro, tkd - ray.rd*dot(tkd, ray.rd)));
}

vec3 firstTorusKnotLineSqDistanceMinimumInside(Ray ray, TorusKnotParameters tkp)
{
    int sections = 3*int(max(tkp.kq,tkp.kp));
    float sectionLength = 2.*PI/float(sections);
    
    float lerningRate = 0.008/(max(tkp.kq,tkp.kp)-0.75);
    const int maxIterations = 100;//50
    
    float minDist;
    float bestT;
    bool found = false;
    
    for(int j = 0; j < sections; j++)
    {
        float t = sectionLength * float(j);
        bool failed = false;
        
        for(int i = 0; i < maxIterations; i++)
        {
            float dt = torusKnotLineSqDistanceDerivative(t, ray, tkp);
            
            if(abs(dt) < 0.1)break;
            
            t -= lerningRate*dt;
            
            
            if(t != clamp(t, sectionLength * (float(j)-1.), sectionLength * (float(j)+1.)))
            {
                failed = true;
                break;
            }
        }
        if(failed)continue;
        
        float lineSqDist = torusKnotLineSqDistance(t, ray, tkp);
        
        if(lineSqDist <= sq(tkp.r3))
        {
            float distAlongD = dot(torusKnot(t, tkp) - ray.ro, ray.rd);

            if(!found || distAlongD < minDist)
            {
                minDist = distAlongD;
                bestT = t;
            }
            
            found = true;
        }
    }
    
    return vec3(bestT, minDist, found ? 1. : 0.);
}

float dot01(vec3 a, vec3 b)// [-1, 1] => [0 ,1]
{
    return (dot(a, b) + 1.)/2.;
}

Ray intersect(Ray ray, TorusKnotParameters tkp)
{
    const int maxIterations = 50;
    
    vec3 res = firstTorusKnotLineSqDistanceMinimumInside(ray, tkp);
    
    if(res[2] < 0.5)
    {
        return Ray(vec3(0), vec3(0));
    }
    
    float t = res[0];
    vec3 p = ray.ro + res[1] * ray.rd;

    for(int i = 0; i < maxIterations; i++)
    {
        t = minimizeDistance(t, p, tkp);
        float d = sqrt(torusKnotSqDistance(t, p, tkp)) - tkp.r3;
        p += d * ray.rd;

        if(abs(d) < 0.01)break;
    }

    vec3 normal = normalize(torusKnot(t, tkp) - p);
    
    return Ray(p, normal);
}

int gcd(ivec2 v)
{
    while(v.x != v.y)
    {
        if(v.x > v.y)
            v.x -= v.y;
        else
            v.y -= v.x;
    }
    
    return v.x;
}

void main(void)
{
    vec2 uv = 5.*gl_FragCoord.xy/resolution.xy;
    ivec2 kpkq = ivec2(uv) + 1;
    uv = mod(uv, 1.);
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;
    
    
    //vec2 uv = (gl_FragCoord.xy - resolution.xy/2.)/resolution.y;

    vec2 angles = PI*vec2(0.7, 0.25)*(sic(0.5*time) + vec2(0, 1));
    vec2 sic0 = sic(angles[0]);
    vec2 sic1 = sic(angles[1]);
    
    vec3 f = vec3(sic1.x * sic0, -sic1.y);
    vec3 u = vec3(sic1.y * sic0, sic1.x);
    vec3 r = -cross(u, f);
    
    vec3 ro = -8.*f;
    
    float zoom = 1.;
    
    ////////////////////////////////////The torus knot parameters//////////////////////////////////////////
    float kp = 3., kq = 5., r1 = 2., r2 = 1., r3 = 0.4;// + 0.3*(sin(time)+1.)/2.;//Change kp and kq!
    // p and q are flipped. The parameters: 'lerningRate', 'maxIterations' and 'sections' also may need to be changed.
    
    /*
    ivec2 kpkq = ivec2(10.*mouse*resolution.xy.xy/resolution.xy) + 1;
    kpkq /= gcd(kpkq);
    */
    
    kp = float(kpkq.x);
    kq = float(kpkq.y);
    
    TorusKnotParameters tkp = TorusKnotParameters(kp, kq, r1, r2, r3);
    
    vec3 rd = normalize(zoom * f + uv.x*r + uv.y*u);
    
    
    Ray lr = intersect(Ray(ro, rd), tkp);
    
    vec3 col;
    
    if(sq(lr.rd) < 0.5)
    {
        col = vec3(0);
    }
    else
    {
        //reflections
        for(int i = 0; i < 0; i++)
        {
            Ray nr = intersect(lr, tkp);
            if(sq(nr.rd) < 0.5)
                break;

            nr.ro -= 0.01*nr.rd;
            lr = nr;
        }
        
        float offset = 2.*time;

        vec2 sicRZ = sic(0.);//PI/2./4.);//22.5°

        vec3 redLight = vec3(sicRZ.x * sic(offset), sicRZ.y);
        vec3 blueLight = vec3(sicRZ.x * sic(2.*PI/3. + offset), sicRZ.y);
        vec3 greenLight = vec3(sicRZ.x * sic(2.*2.*PI/3. + offset), sicRZ.y);

        col = vec3(dot01(lr.rd, -redLight), dot01(lr.rd, -blueLight), dot01(lr.rd, -greenLight));
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
