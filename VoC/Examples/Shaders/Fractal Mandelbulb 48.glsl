#version 420

// original https://www.shadertoy.com/view/wtcyWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_STEPS = 1000;
const float EPSILON = 0.001;

mat4 rotate(float a) {
    float sine = sin(a);
    float cosine = cos(a);
    mat4 mat = mat4(
    cosine, 0, sine, 0,
    0, 1, 0, 0,
    -sine, 0, cosine, 0,
    0, 0, 0, 1
    );
    return inverse(mat);
}

float sdfMandelbulb( vec3 p )
{
    vec3 w = p;
    float m = dot(w,w);

    vec4 trap = vec4(abs(w),m);
    float dz = 1.0;
    
    
    for( int i=0; i<4; i++ )
    {
#if 0
        float m2 = m*m;
        float m4 = m2*m2;
        dz = 8.0*sqrt(m4*m2*m)*dz + 1.0;

        float x = w.x; float x2 = x*x; float x4 = x2*x2;
        float y = w.y; float y2 = y*y; float y4 = y2*y2;
        float z = w.z; float z2 = z*z; float z4 = z2*z2;

        float k3 = x2 + z2;
        float k2 = inversesqrt( k3*k3*k3*k3*k3*k3*k3 );
        float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
        float k4 = x2 - y2 + z2;

        w.x = p.x +  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
        w.y = p.y + -16.0*y2*k3*k4*k4 + k1*k1;
        w.z = p.z +  -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;
#else
        dz = 8.0*pow(sqrt(m),7.0)*dz + 1.0;
        //dz = 8.0*pow(m,3.5)*dz + 1.0;
        
        float r = length(w);
        float b = 8.0*acos( w.y/r);
        float a = 8.0*atan( w.x, w.z );
        w = p + pow(r,8.0) * vec3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );
#endif        
        
        trap = min( trap, vec4(abs(w),m) );

        m = dot(w,w);
        if( m > 256.0 )
            break;
    }

    //resColor = vec4(m,trap.yzw);

    return 0.25*log(m)*sqrt(m)/dz;}

float sceneSDF( vec4 pos )
{
    // SDF of sphere with radius 1
    return sdfMandelbulb((rotate(time / 3.0) * pos).xyz / 2.0) * 2.0;
}

float raymarch( in float start, in float end, in vec4 eyePos, in vec4 viewRay ) 
{
    float depth = start;
    
    for (int i = 0; i < MAX_STEPS; i++) 
    {
        float dist = sceneSDF(eyePos + depth * viewRay);
        
        if (dist < EPSILON) 
        {
            return depth;
        }
        
        depth += dist;
        
        if (depth >= end)
        {
            return end;
        }
    }
    
    return end;
}

vec4 estimateNormal(vec4 p) 
{
    return normalize(vec4(
        sceneSDF(vec4(p.x + EPSILON, p.y, p.z, p.w)) - sceneSDF(vec4(p.x - EPSILON, p.y, p.z, p.w)),
        sceneSDF(vec4(p.x, p.y + EPSILON, p.z, p.w)) - sceneSDF(vec4(p.x, p.y - EPSILON, p.z, p.w)),
        sceneSDF(vec4(p.x, p.y, p.z + EPSILON, p.w)) - sceneSDF(vec4(p.x, p.y, p.z - EPSILON, p.w)),
        sceneSDF(vec4(p.x, p.y, p.z, p.w + EPSILON)) - sceneSDF(vec4(p.x, p.y, p.z, p.w - EPSILON))
    ));
}

void main(void)
{
    const vec4 eye = vec4(0, 0, -4, 0);
    float aspect = resolution.x / resolution.y;
    vec4 ray = normalize(vec4(((gl_FragCoord.xy / resolution.xy) - vec2(0.5)) * vec2(aspect, 1), 1, 0));

    float march = raymarch(EPSILON, 100.0, eye, ray);

    if (march > 100.0 - 1.0) 
    {
        glFragColor = vec4(0, 0, 0, 1);
        return;
    }
    
    const vec3 surfaceColor = vec3(0.5, 0.5, 1.0);
    const float ambientLight = 0.2;
    vec4 lightPos = vec4(0.0, 2.0, -4.0, 0.0);
    
    vec4 collisionPoint = eye + march * ray;
    vec4 normal = estimateNormal(collisionPoint);
    vec4 toLight = normalize(lightPos - collisionPoint);
    float ndotl = dot(normal, toLight);
    vec3 color = surfaceColor * clamp(ndotl, ambientLight, 1.0);
    glFragColor = vec4(color, 1.0);
}
