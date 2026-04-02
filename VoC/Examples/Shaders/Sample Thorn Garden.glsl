#version 420

// original https://www.shadertoy.com/view/3ldXD2

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

float sdTet(vec3 p, float r) {
    const vec3 c = normalize(vec3(1.,-1.,1.));
    return max(max(max(dot(p, c.xxx) - r, dot(p, c.yyx) - r), dot(p, c.xyy) - r), dot(p, c.yxy) - r);
}

vec3 opRepeat(vec3 p, vec3 spacing) {
    return mod(p, spacing) - 0.5 * spacing;
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

// assumes normalized axis
mat3 makeRotation(vec3 axis,float angle) {
    
    float c = cos(angle), s = sin(angle);
    float mc = 1. - c;
    float sz = s * axis.z;
    float sy = s * axis.y;
    float sx = s * axis.x;
    float mx = mc * axis.x;
    float my = mc * axis.y;
    float mz = mc * axis.z;
    
    return mat3(c + mx * axis.x,
                mx * axis.y - sz,
                mx * axis.z + sy,
                mx * axis.y + sz,
                c + my * axis.y,
                my * axis.z - sx,
                mx * axis.z - sy,
                my * axis.z + sx,
                c + mz * axis.z);
}

// -----------------

mat3 innerRotation;

float d(vec3 position) {
    position = rX(position, time * 0.13);
    float fScale = 0.79 + sin(time * 0.9) * 0.013;
    float accumulatedScale = 1.;
    
    for(int i = 0; i < 8; i++) {
        position = abs(position);
        position *= fScale;
        accumulatedScale *= fScale;
        position -= (0.0137 + 0.001 * sin(time * 0.6 + 1.));
        position = innerRotation * position;
    }
    float cutoutAmount = pow(sin(time * 0.231), 4.);
    float innerCutout = sdSphere(position, 0.014 + cutoutAmount * 0.002);//sdTet(-position,0.003 + cutoutAmount * 0.009); // sdSphere(position, 0.009 + cutoutAmount * 0.007);
    float outerCrop = sdSphere(position, 0.021 + sin(time * 0.831 + 2.) * 0.003);
    return opInt(opSub(sdTet(position, 0.01), innerCutout), outerCrop) / accumulatedScale;
}

vec3 gradient(vec3 p, float v) {
    const vec3 eps = vec3(0.0001, 0.0, 0.0);
    return (vec3(d(p + eps.xyy), d(p + eps.yxy), d(p + eps.yyx)) - v) / eps.x;
}

vec4 march(vec3 from, vec3 towards, float prec) {
    vec3 lastSamplePosition = from;
    float lastDistance = 0.0;
    for(int i = 0; i < 70; i++) {
        vec3 samplePosition = lastSamplePosition + max(lastDistance, prec) * towards;
        float cDist = d(samplePosition);
        
        lastSamplePosition = samplePosition;
        lastDistance = cDist;
        
        if (cDist < 0.0) {
            return vec4(samplePosition, cDist);
        }
    }
    return vec4(1.0);
}

// ambient occlusion using iq’s technique from http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf
float occlusion(vec3 position, vec3 normal) {
    const float aoStep = 0.04;
    float aoAcc = 0.;
    const float distanceScale = 0.005; // decrease for less attenuation of shadows
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float sampleDistance = aoStep * fi;
        aoAcc += (sampleDistance - max(0.,d(position + normal * sampleDistance))) / exp2(fi * distanceScale);
    }
    return aoAcc;
}

vec3 palette(float v) {
    return vec3(0.5) + 0.5 * cos(6.28318 * (v + vec3(0.0,0.333,0.667)));
}

// soft shadows also using iq’s technique — https://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float shadow(vec3 origin, vec3 direction, float sharpness) {
    const float maxDistance = 2.;
    float amount = 1.;
    float totalDistance = 0.;
    for(int i = 0; i < 70; i++) {
        float localDistance = d(origin);
        amount = min(amount, 0.5 + 0.5 * localDistance / (sharpness * totalDistance));
        if (localDistance < 0.) break;
        origin += direction * max(0.002, localDistance);
    }
    
    amount = max(amount, 0.);
    return amount * amount * (3. - 2. * amount);
    
}

vec3 lightSurface(vec3 position, vec3 normal, vec3 toEye) {
    vec3 toLight = normalize(vec3(-0.4, 1.0, 0.6)  - position);
    float ndotL = max(0.0, dot(normal, toLight));
    float ndotH = max(0.0, dot(normal, normalize(toEye + toLight)));
    float nDotV = max(0., dot(normal, toEye));
    const float diffuse = 1.;
    float ambience = 0.1 + max(0., dot(normal, vec3(0.,-1.,0.))) * 0.4;
    const float specular = 0.3;
    float ao = (1.0 - occlusion(position, normal));
    float fres = pow(1. - nDotV, 8.);
    float shadowAmount = shadow(position + normal * 0.01, toLight, .5);
    
    vec3 color = vec3((ndotL * diffuse + pow(ndotH, 4.) * specular) * shadowAmount + ao * (ambience + fres)) * palette(nDotV * -0.5 + 0.6 + time * 0.1);
    return color;
}

#define ANTIALIASING_SAMPLES 3

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy / resolution.xy - 0.5);
    uv.x *= resolution.x / resolution.y;
    const vec3 cameraLookAt = vec3(0.0, -0.04, 0.0);
    vec3 cameraPosition = vec3(0.0, 0.2, 1.5) * 1.7;
    vec3 cameraForward = normalize(cameraLookAt - cameraPosition);
    vec3 cameraRight = cross(cameraForward, vec3(0.0, 1.0, 0.0));
    vec3 cameraUp = cross(cameraRight, cameraForward);
    vec3 rayDirection = normalize(uv.x * cameraRight + uv.y * cameraUp + 3.0 * cameraForward);
    
    innerRotation = makeRotation(normalize(vec3(1.,2.,-3.)), time * 0.122 + sin(time * 0.23) * 0.1);
    
    vec3 color = vec3(0.);
    for (int i = 0; i < ANTIALIASING_SAMPLES; i++) {
        vec3 aaOffset = 0.002 * (cameraRight * float(i == 1 || i == 3) + cameraUp * float(i == 0 || i == 2));
        vec4 marchResult = march(cameraPosition + aaOffset, rayDirection, 0.0001);
        if (marchResult.w > 0.0) {
            color += vec3(0.0); // “sky” color
        } else {
            vec3 position = marchResult.xyz;
            color += lightSurface(position, gradient(position, marchResult.w), -rayDirection);
        }
    }
    color /= float(ANTIALIASING_SAMPLES);
    color = pow(color, vec3(1.2)) * 1.5;
    glFragColor = vec4(color, 1.0);
}
