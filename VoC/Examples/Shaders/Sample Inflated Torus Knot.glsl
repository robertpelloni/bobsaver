#version 420

// original https://www.shadertoy.com/view/WsyGz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433832795

float fOverDerF(float t, vec3 p)
{
    
    float sint = sin(t);
    float cost = cos(t);
    
    float sin2t = 2.0*sint*cost;//sin(2.0*t);
    float cos2t = cost*cost - sint*sint;//cos(2.0*t);
    
    float sin4t = 2.0*sin2t*cos2t;//sin(4.0*t);
    
    float sin3t = sin(3.0*t);
    float cos2tSq = cos2t*cos2t;
    float cos3t = cos(3.0*t);
    
    return (2.0*p.x*sint + p.x*sin2t + 2.0*p.x*sin4t - 3.0*p.y*cos3t - 2.0*p.z*cost - 4.0*p.z*cos2tSq + p.z*cos2t + 2.0*p.z - 6.0*sin3t)/(2.0*p.x*cost + 16.0*p.x*cos2tSq + 2.0*p.x*cos2t - 8.0*p.x + 9.0*p.y*sin3t + 2.0*p.z*sint - 2.0*p.z*sin2t + 8.0*p.z*sin4t - 16.0*cos2tSq*cos2t + 12.0*cos2t - 18.0*cos3t + 4.0*cos(6.0*t));
    
    
    //return (2.0*p.x*sin(t) + p.x*sin(2.0*t) + 2.0*p.x*sin(4.0*t) - 3.0*p.y*cos(3.0*t) - 2.0*p.z*cos(t) - 4.0*p.z*pow(cos(2.0*t), 2.0) + p.z*cos(2.0*t) + 2.0*p.z - 6.0*sin(3.0*t))/(2.0*p.x*cos(t) + 16.0*p.x*pow(cos(2.0*t), 2.0) + 2.0*p.x*cos(2.0*t) - 8.0*p.x + 9.0*p.y*sin(3.0*t) + 2.0*p.z*sin(t) - 2.0*p.z*sin(2.0*t) + 8.0*p.z*sin(4.0*t) - 16.0*pow(cos(2.0*t), 3.0) + 12.0*cos(2.0*t) - 18.0*cos(3.0*t) + 4.0*cos(6.0*t));
}

vec3 torusKnot(float t)
{
    return vec3((cos(3.0*t) + 2.0)*cos(t), sin(3.0*t), (cos(3.0*t) + 2.0)*sin(t));
}
vec3 torusKnotDer(float t)
{
    return vec3(sin(t)*(-(cos(3.*t) + 2.)) - 3.*sin(3.*t)*cos(t), 3.*cos(3.*t), cos(t)*(cos(3.*t) + 2.) - 3.*sin(t)*sin(3.*t));
}

float lengthSq(vec3 p)
{
    return dot(p, p);
}

float torusKnotDist(vec3 p, out vec3 closestPoint)
{
    int samplePointsNum = 12;
    
    float jump = 2.0 * PI / float(samplePointsNum);
    
    float minDistSq = -1.0;
    float minT;
    
    for(int i = 0; i < samplePointsNum; i++)
    {
        float cT = jump * float(i);
        
        cT -= fOverDerF(cT, p);
        
        float cDistSq = lengthSq(torusKnot(cT) - p);
        
        if(minDistSq == -1.0 || cDistSq < minDistSq)
        {
            minDistSq = cDistSq;
            minT = cT;
        }
    }

    minT -= fOverDerF(minT, p);
    
    
    closestPoint = torusKnot(minT);
    
    return distance(closestPoint, p);
}

float pulse(float x, float a, float b)
{
    return pow(1./(pow(abs(x), a) + 1.), b);
}

float getT(vec3 closestPoint)
{
    return atan(closestPoint.z, closestPoint.x);
}
float getS(float t, vec3 p, vec3 closestPoint)
{
    vec3 normal = vec3(cos(3.0*t)*cos(t), sin(3.0*t), cos(3.0*t)*sin(t));
    vec3 cpToP = normalize(p - closestPoint);
    
    float angle = acos(clamp(dot(normal, cpToP), -1., 1.));
    
    
    float angSign = sign(dot(cross(normal, cpToP), torusKnotDer(t)));
    
    return angle * angSign;
}

float myMod(float a, float b)
{
    return fract(a / b) * b;
}

float spikyTorusKnotDist(vec3 p, out vec3 closestPoint)
{
    float tnd = torusKnotDist(p, closestPoint);
    
    float t = getT(closestPoint);
    float s = getS(t, p, closestPoint);
    
    s = mod(s+PI/2., 2.*PI) - PI;
    
    float bump = PI / 24.;
    
    t += bump;
        
    t = mod(t, 2.*bump);
    
    t -= bump;
    
    
    
    
        
    //t = mod(t, PI/2.);
            
    t *= 10.;
    s *= 2.;

    
    return tnd - 0.5*(exp(-t*t -s*s));
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xx - (resolution.xy/resolution.xx)/2.0;
    
    float time = 0.1 * time;
    
    
    float az = (2.*PI*time);
    float po = PI/2. * sin(2.*PI*time);
    
    
    vec3 camera = vec3(cos(po) * cos(az), sin(po), cos(po) * sin(az));
    vec3 cz = -camera;
    vec3 cy = vec3(sin(-po) * cos(az), cos(-po), sin(-po) * sin(az));
    vec3 cx = cross(cy, cz);
    camera *= 14.;

    float zoom = 1.;
    
    
    
    
    vec3 sp = normalize(uv.x * cx + uv.y * cy + zoom * cz);
    
    vec3 p = camera;
    
    float hitDistance = 0.2;
    
    
    vec3 lastClosestCurvePoint;
    float totalDist = 0.0;
    float lastDist = -1.0;
    for(int i = 0; i < 30; i++)
    {
        p += sp * lastDist;
        
        lastDist = torusKnotDist(p, lastClosestCurvePoint) - 0.5;
        
        totalDist += lastDist;
        
        //if(lastDist < 0.2)break;
    }
    
    
    
    
    vec3 col = vec3(0);
    
    
    
    if(lastDist < 0.2)
    {
        float t = getT(lastClosestCurvePoint);
        float s = getS(t, p, lastClosestCurvePoint);
        
        
        //s = mod(s+PI/2., 2.*PI) - PI;
    
        float bump = PI / 24.;

        t += bump;

        t = mod(t, 2.*bump);

        t -= bump;

        t *= 10.;
        s *= 2.;
        
        
        float time = 0.3*time;
        
        
        col = (1./(totalDist - 14. + 4.)+0.1) * mix(hsv2rgb(vec3(time + 0.5, 1, 1)), hsv2rgb(vec3(time, 1, 1)), (exp(-t*t -s*s)));
    }
    //col = smoothstep(0.3, 0., lastDist) * vec3(1./(totalDist - 14. + 4.)+0.1);
        

    glFragColor = vec4(col,1.0);
}
