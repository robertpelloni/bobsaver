#version 420

// original https://www.shadertoy.com/view/3dKSRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ------

float sdCylinder( vec3 p, float r, float h ) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdCube(vec3 p, float b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

vec3 opRepeat(vec3 p, vec3 spacing) {
    return mod(p, spacing) - 0.5 * spacing;
}

vec3 opRepeatLimited(vec3 p, vec3 spacing, vec3 limit) {
    return p - spacing * clamp(round(p / spacing), -limit, limit);
}

float opSub(float d1, float d2) {
    return max(d1, -d2);
}

float opAdd(float d1, float d2) {
    return min(d1, d2);
}

float opInt(float d1, float d2) {
    return max(d1, d2);
}

vec3 rX(vec3 p, float a) {
    vec3 q = p;
    float c = cos(a);
    float s = sin(a);
    q.y = c * p.y - s * p.z;
    q.z = s * p.y + c * p.z;
    
    return q;
}

vec3 rY(vec3 p, float a) {
    vec3 q = p;
    float c = cos(a);
    float s = sin(a);
    q.x = c * p.x + s * p.z;
    q.z = -s * p.x + c * p.z;
    
    return q;
}

vec3 rZ(vec3 p, float a) {
    vec3 q = p;
    float c = cos(a);
    float s = sin(a);
    q.x = c * p.x - s * p.y;
    q.y = s * p.x + c * p.y;
    
    return q;
}

float sdTriPrism( vec3 p, vec2 h ) {
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

// -----------------

float planeDistance(vec3 position) {
    vec3 wingP = position.xzy * vec3(2.0,1.5,2.0);
    wingP.x = abs(wingP.x);
    wingP.z -= 0.3 * wingP.x; // tilt by skewing the space
    
    float wingDistance = sdTriPrism(wingP, vec2(1.0,0.02));
    
    vec3 bodyP = position.yzx * vec3(4.0,1.5,1.0);
    
    float bodyDistance = max(sdTriPrism(bodyP, vec2(1.0, 0.01)), dot(position, vec3(0.0,1.0,0.0)));
    
    return min(wingDistance, bodyDistance);
}

float d(vec3 position) {
    vec3 warpedPosition = position + sin(position.x * 2.0 + time * 2.3) * 0.1;
    return planeDistance(rZ(opRepeat(warpedPosition, vec3(2.0)), cos(time * 1.2) * 0.15));
}

vec3 gradient(vec3 p, float v) {
    const vec3 eps = vec3(0.001, 0.0, 0.0);
    return normalize((vec3(d(p + eps.xyy), d(p + eps.yxy), d(p + eps.yyx)) - v) / eps.x);
}

vec4 march(vec3 from, vec3 towards, float prec) {
    vec3 lastSamplePosition = from;
    float lastDistance = 0.0;
    for(int i = 0; i < 100; i++) {
        vec3 samplePosition = lastSamplePosition + max(lastDistance * 0.4, prec) * towards;
        float cDist = d(samplePosition);
        
        lastSamplePosition = samplePosition;
        lastDistance = cDist;
        
        if (cDist < 0.0) {
            return vec4(samplePosition, cDist);
        }
    }
    return vec4(1.0);
}

vec3 lightSurface(vec3 position, vec3 normal, vec3 toEye) {
    vec3 toLight = normalize(vec3(0.3, 0.9, 0.9));
    float ndotL = max(0.0, dot(normal, toLight));
    float ndotV = max(0.0, dot(normal, toEye));
    float ndotH = max(0.0, dot(normal, normalize(toEye + toLight)));
    const float diffuse = 0.8;
    vec3 ambience = mix(vec3(0.2,0.25,0.3), vec3(0.2,0.4,0.6), dot(normal, vec3(0., 1., 0.)) * -0.5 + 0.5);
    const float specular = 0.6;
    vec3 color = vec3((ndotL * diffuse + pow(ndotH, 2.) * specular) + ambience);
    return color;
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy / resolution.xy - 0.5);
    uv.x *= resolution.x / resolution.y;
    const vec3 cameraLookAt = vec3(0.0, -0.05, 0.0);
    vec3 cameraPosition = vec3(0.75,0.6,1.5);
    vec3 cameraForward = normalize(cameraLookAt - cameraPosition);
    vec3 cameraRight = cross(cameraForward, vec3(0.0, 1.0, 0.0));
    vec3 cameraUp = cross(cameraRight, cameraForward);
    vec3 rayDirection = normalize(uv.x * cameraRight + uv.y * cameraUp + 3.0 * cameraForward);
    
    cameraPosition += time * vec3(0.0,-0.2,-1.0);
    
    vec4 marchResult = march(cameraPosition, rayDirection, 0.001);
    vec3 backgroundColor = mix(vec3(0.4,0.75,1.0), vec3(0.2,0.5,0.9), (uv.y + 0.5));
    if (marchResult.w > 0.0) {
        glFragColor = vec4(backgroundColor, 1.0); // “sky” color
    } else {
        vec3 position = marchResult.xyz;
        float fogDistance = max(0., length(position - cameraPosition) - 4.);
        vec3 litColor = lightSurface(position, gradient(position, marchResult.w), -rayDirection);
        
        glFragColor = vec4(mix(litColor, backgroundColor, 1.0 - exp(-fogDistance * 0.1)), 1.0);
    }
}
