#version 420

// original https://www.shadertoy.com/view/WtsGzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

float sceneSDF(vec3 p)
{
    float time = mod(time, 3.1415 * 1.0);
    
    vec3 boxSize = vec3(1.0, 1.0, 1.0);
    
    mat3 rot1 = mat3(
        cos(time), sin(time), 0.0,
        sin(time), -cos(time), 0.0,
        0.0, 0.0, 1.0);

    mat3 rot2 = mat3(
        -cos(time), 0.0, sin(time),
        0.0, 1.0, 0.0,
        sin(time), 0.0, cos(time));
    
    mat3 rot3 = mat3(
        1.0, 0.0, 0.0,
        0.0, cos(time), sin(time),
        0.0, sin(time), -cos(time));
    
    return unionSDF(
        sdBox(rot1 * (p + vec3(-1,-1,0)) - vec3(1.0, 1.0, 0.0), boxSize),
        unionSDF(
            sdBox(rot2 * (p + vec3(-1, 0, -1)) - vec3(1.0, 0.0, 1.0), boxSize),
            sdBox(rot3 * (p + vec3(0, -1, -1)) - vec3(0.0, 1.0, 1.0), boxSize)
        )
    );
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
    float cameraFar = 20.0f;
    vec3 eyePositionWS = vec3(7.0f, 7.0f, 7.0f);

    // Viewport calculations
    float aspectRatioInv = resolution.y / resolution.x;
    
    float horizontalFov = cameraNear * tan(cameraHFovAngle * 0.5f);
     float verticalFov = horizontalFov * aspectRatioInv;
    vec2 cameraViewportExtent = vec2(horizontalFov, verticalFov);
    
    vec3 viewRayDirectionWS = vec3(positionNDC * cameraViewportExtent, cameraNear);
    
    viewRayDirectionWS = (viewMatrix(eyePositionWS, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0)) * vec4(viewRayDirectionWS, 0.0)).xyz;        
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
        color = vec3(1.0, 0.0, 0.7) * dotLN + vec3(.1, .1, .1);
    
    glFragColor = vec4(color, 1.0);
}
