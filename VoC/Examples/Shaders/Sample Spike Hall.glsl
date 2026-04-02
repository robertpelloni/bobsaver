#version 420

// original https://www.shadertoy.com/view/MdGyWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_STEPS = 500;
const float MAX_DIST = 200.0;
const float EPSILON = 0.0001;
const float PI = 3.141592654;

vec3 opTransform(vec3 p, mat4 m)
{
    return (m * vec4(p, 1.0)).xyz;
}

vec3 opRep(vec3 p, vec3 c)
{
    return mod(p,c) - 0.5 * c;
}

float dSphere(vec3 p, float r)
{
    return length(p) - r;
}

float dBox(vec3 p, vec3 b)
{
    return length(max(abs(p) - b, 0.0));
}

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

mat4 translationMatrix(vec3 d) {
    return mat4(1, 0, 0, d.x,
                0, 1, 0, d.y,
                0, 0, 1, d.z,
                0, 0, 0, 1);
}

float map(vec3 p)
{
    float m = dBox(p + vec3(0, 0, time * 3.0), vec3(7.0, 7.0, 50));
    
    vec3 q = opTransform(p, rotationMatrix(vec3(0, 0, 1), (p.z) / 20.0 + time / 2.0));
    float box1 = dBox(opRep(q.xyz, vec3(4)), vec3(0.1, 0.1, 2));
    float box2 = dBox(opRep(q.yxz, vec3(4)), vec3(0.1, 0.1, 2));
    float box3 = dBox(opRep(q.zyx, vec3(4)), vec3(0.1, 0.1, 2));
    float box4 = dBox(opRep(q.xzy, vec3(4)), vec3(0.1, 0.1, 2));
    return max(m, min(box1, min(box2, min(box3, box4))));
}

vec3 getNormal(vec3 p)
{
    vec2 eps = vec2(EPSILON, 0.0);
    return normalize(vec3(
        map(p + eps.xyy) - map(p - eps.xyy),
        map(p + eps.yxy) - map(p - eps.yxy),
        map(p + eps.yyx) - map(p - eps.yyx)
    ));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

vec3 screenRay(float fieldOfView, vec2 size, vec2 gl_FragCoord) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

float softShadow(in vec3 ro, in vec3 rd, float mint, float maxt, float k)
{
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t < maxt; )
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

void main(void)
{
    vec3 sun = normalize(vec3(1));
    vec3 eye = vec3(
        0,
        0,
        20.0 - time * 3.0
    );
    vec3 center = vec3(0, 0, -time * 3.0);
    vec3 ro = eye;
    vec3 rd = viewMatrix(eye, center, vec3(0, 1, 0)) * screenRay(90.0, resolution.xy, gl_FragCoord.xy);
    
    int i;
    float dist = 0.0;
    for (i = 0; i < MAX_STEPS; i++)
    {
        float d = map(ro + rd * dist);
        if (d < EPSILON)
            break;
        
        dist += d;
        if (dist > MAX_DIST)
            break;
    }
    
    if (dist > MAX_DIST - EPSILON) {
        glFragColor.rgb = vec3(0);
    } else {
        
        float shadow = softShadow(ro + rd * dist, sun, 0.1, MAX_DIST, 1.0);
        glFragColor.rgb = vec3(max(dist / 50.0, 0.1));
    }
    
    
}
