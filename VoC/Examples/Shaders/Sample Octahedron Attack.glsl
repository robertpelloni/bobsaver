#version 420

// original https://www.shadertoy.com/view/WlXGzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdOctahedron( in vec3 p, in float s)
{
    p = abs(p);
    float m = p.x+p.y+p.z-s;
    vec3 q;
         if( 3.0*p.x < m ) q = p.xyz;
    else if( 3.0*p.y < m ) q = p.yzx;
    else if( 3.0*p.z < m ) q = p.zxy;
    else return m*0.57735027;
    
    float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
    return length(vec3(q.x,q.y-s+k,q.z-k)); 
}

float saturate(float v)
{
    return clamp(v, 0.0, 1.0);
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}

float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

float sdBox(vec3 p, vec3 b)
{
      vec3 d = abs(p) - b;
      return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sphereSDF(vec3 p)
{
    return length(p) - 1.0;
}

const int MAX_MARCHING_STEPS = 200;
const float EPSILON = 0.001f;

float onion( in float d, in float h )
{
    return abs(d)-h;
}

float opRep( in vec3 p, in vec3 c)
{
    vec3 q = mod(p,c)-0.5*c;
    return intersectSDF(onion(onion(sdOctahedron(q, 0.5),0.05), 0.01), -sdBox(q+vec3(0,0,-1.0+ 2.0 *mod(time*.3, 1.0)), vec3(1,1,0.14)));
}

float sceneSDF(vec3 p)
{
    return opRep(p + vec3(time,time*0.5,0), vec3(2.0, 2.0, 2.0));
}

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON) {
            return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec3 estimateNormal(vec3 p)
{
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

const float pi = 3.14159265358;

float deg2rad(float angleDeg)
{
     return (angleDeg * pi) / 180.f;
}

void main(void)
{
    vec2 positionUV = gl_FragCoord.xy / resolution.xy;
    vec2 positionNDC = 2.0 * positionUV - 1.0;
    positionNDC.y = -positionNDC.y;
    
    // Camera setup
    float cameraHFovAngle = deg2rad(55.f);
    float cameraNear = 0.1f;
    float cameraFar = 200.0f;
    vec3 eyePositionWS = vec3(3.5f, 1.5f + sin(time * 0.2), 6.5f);

    // Viewport calculations
    float aspectRatioInv = resolution.y / resolution.x;
    
    float horizontalFov = cameraNear * tan(cameraHFovAngle * 0.5f);
     float verticalFov = horizontalFov * aspectRatioInv;
    vec2 cameraViewportExtent = vec2(horizontalFov, verticalFov);
    
    vec3 viewRayDirectionWS = vec3(positionNDC * cameraViewportExtent, cameraNear);
    
    viewRayDirectionWS = (viewMatrix(eyePositionWS, vec3(0.5, 0.5, 0.5 + cos(time * 0.5) * 0.5), vec3(0.0, 0.0, 1.0)) * vec4(viewRayDirectionWS, 0.0)).xyz;        
    viewRayDirectionWS = normalize(-viewRayDirectionWS);
    
    float rayDepth = shortestDistanceToSurface(eyePositionWS, viewRayDirectionWS, cameraNear, cameraFar);

    vec3 p = eyePositionWS + rayDepth * viewRayDirectionWS;
    
    vec3 lightPosWS = vec3(2.0, 4.0, 6.0);
    vec3 normalWS = estimateNormal(p);
    vec3 L = normalize(lightPosWS - p);
    vec3 V = normalize(eyePositionWS - p);
    vec3 R = normalize(reflect(-L, normalWS));
    
    float dotLN = saturate(dot(L, normalWS));
    float dotRV = saturate(dot(R, V));
        
    // Output some color
    vec3 color = vec3(0.0);
    
    if (rayDepth > cameraFar - EPSILON)
    {
        // Didn't hit anything
        color = vec3(0.0);
    }
    else
        color = vec3(0.9, 0.7, 0.2) * dotLN + vec3(.1, .1, .1);
    
    // Distance fog
    vec3 fogColor = vec3(0.9, 0.3, 0.2);
    color = mix(fogColor, color, 1.0 / (1.0 + rayDepth * 0.1));
    
    // Output color
    glFragColor = vec4(color, 1.0);
}
