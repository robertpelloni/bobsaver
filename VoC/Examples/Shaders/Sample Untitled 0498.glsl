#version 420

#define PI 3.1415926535897932384626433832795
#define PI_2 1.57079632679489661923
#define PI_4 0.785398163397448309616

#define MAXSTEPS 100
#define MAXDIST 10.0
#define EPSILON .000001
#define SPECULAR_STRENGTH 50.0

//#define ANTIALISING

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

vec3 rotateX(vec3 v, float a) {
    vec2 yz = rotate(v.yz, a);
    return vec3(v.x, yz[0], yz[1]);
}

vec3 rotateY(vec3 v, float a) {
    vec2 xz = rotate(v.xz, a);
    return vec3(xz[0], v.y, xz[1]);
}

vec3 rotateZ(vec3 v, float a) {
    vec2 xy = rotate(v.xy, a);
    return vec3(xy[0], xy[1], v.z);
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float sphereSDF(vec3 pos, vec3 spherePosition, float radius) {
    return distance(pos, spherePosition) - radius;
}

float boxSDF(vec3 pos, vec3 boxPosition, vec3 size) {
    pos -= boxPosition;
    vec3 q = abs(pos) - size;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

float smoothUnionSDF(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sceneSDF(vec3 pos) {
    float spheres = 0.;
    spheres = sphereSDF(mod(pos, vec3(1, 1, 1) * 2.0), vec3(1, 1, 1), 0.4);
    for (int i = 0; i < 5; i++) {
        vec3 spherePos = vec3(1, 1, 1);
        vec3 sphereOffset = vec3(
            sin(time * (2.0 + float(i) / 3.) + float(i)) / 2.0,
            0,
            0
        );
        sphereOffset = rotateY(sphereOffset, float(i));
        sphereOffset = rotateZ(sphereOffset, float(i*100));
        spheres = smoothUnionSDF(spheres, sphereSDF(mod(pos + sphereOffset, spherePos * 2.0), spherePos, 0.1), 0.1);
    }
    
    return spheres;
    
    vec3 spherePosition = vec3(1, 1, 1);
    float sphere = sphereSDF(mod(pos, spherePosition * 2.0), spherePosition, 0.4);
    
    vec3 spherePosition2 = vec3(1, 1, 1);
    float sphere2 = sphereSDF(mod(pos + vec3(sin(time/2.)/2.4,sin(time)/2.4,cos(time)/2.4), spherePosition2 * 2.0), spherePosition2, 0.2);
    
    return smoothUnionSDF(sphere, sphere2, 0.1);
    
    vec3 box1Position = vec3(1, 1, 1);
    vec3 box1Offset = vec3(-0.2, -0.2, -0.2);
    vec3 box1Size = vec3(0.1, 0.1, 0.1);
    float box1 = boxSDF(mod(pos + box1Offset, box1Position * 2.0), box1Position, box1Size);
    
    vec3 box2Position = vec3(1, 1, 1);
    vec3 box2Offset = vec3(0.2, 0.2, 0.2);
    vec3 box2Size = vec3(0.1, 0.1, 0.1);
    float box2 = boxSDF(mod(pos + box2Offset, box2Position * 2.0), box2Position, box2Size);
    
    vec3 box3Position = vec3(1, 1, 1);
    vec3 box3Offset = vec3(0, 0, 0);
    vec3 box3Size = vec3(0.1, 0.1, 0.1);
    float box3 = boxSDF(mod(pos + box3Offset, box3Position * 2.0), box3Position, box3Size);
    
    float boxes = unionSDF(box1, unionSDF(box2, box3));
    
    float ratio = (sin(time * 2.0) + 1.0) / 2.0;
    //ratio = 0.5;
    return mix(sphere, boxes, ratio);
    //return unionSDF(sphere, box);
}

float legoSceneSDF(vec3 pos) {
    //pos = mod(pos, vec3(2,2,2));
    pos = rotateZ(pos, mouse.x / resolution.x * PI * 2.0);
    
    float outerBox = boxSDF(pos, vec3(0,-0.1,1), vec3(0.318,0.096,0.158));
    float innerBox = boxSDF(pos - vec3(0, -0.011 ,0), vec3(1,1,1), vec3(0.294,0.086,0.134));
    
    return max(outerBox, -innerBox);
}
    
float trace(vec3 from, vec3 direction) {
    float totalDistance = 0.;
    for (int i = 0; i < MAXSTEPS; i++) {
        vec3 p = from + totalDistance * direction;
        
        float dist = sceneSDF(p);
        //float dist = legoSceneSDF(p);
        
        totalDistance += dist;
        
        if (dist < EPSILON) {
            return totalDistance;
        }
        
        if (totalDistance >= MAXDIST) {
            return totalDistance;
        }
    }
    return totalDistance;
}

vec4 estimateNormalAndDistance(vec3 p, vec3 direction) {
    float epsilon = 0.00005;
    float centerDistance = trace(p, direction);
    if (centerDistance >= MAXDIST) {
        return vec4(0,0,0,centerDistance);
    } else {
        float xDistance = trace(p + vec3(epsilon, 0, 0), direction);
        float yDistance = trace(p + vec3(0, epsilon, 0), direction);
        float zDistance = trace(p + vec3(0, 0, epsilon), direction);
        return vec4(normalize((vec3(xDistance, yDistance, zDistance) - centerDistance) / epsilon), centerDistance);
    }
}

float degToRad(float angle) {
    return angle *= PI / 180.0;
}

vec4 addLight(vec4 base, vec3 normal, vec3 direction, vec3 color, float strength) {
    float light = pow(max(0.0, dot(normal, normalize(direction))), 1.5);
    float lightSpecular = pow(light, SPECULAR_STRENGTH);
    
    base.r += light * color.r * strength;
    base.g += light * color.g * strength;
    base.b += light * color.b * strength;
    
    base.r += lightSpecular;
    base.g += lightSpecular;
    base.b += lightSpecular;
    
    return base;
}

vec4 normalToColor(vec3 normal, vec4 base) {
    vec4 lightLayer = vec4(0,0,0,1);
    lightLayer = addLight(lightLayer, normal, vec3(1,sin(time * 2.) + 1.,-1), vec3(0.1, 0.6, 0.9), 1.0);
    lightLayer = addLight(lightLayer, normal, vec3(-1,-1,-1), vec3(0.8, 0.2, 0.1), 1.0);
    lightLayer = addLight(lightLayer, normal, vec3(0,0,1), vec3(1, 1, 0), 1.0);
    
    return base * lightLayer;
}

vec4 normalToFinalColor(vec3 normal, float dist) {
    float angleX = acos(dot(normal, normalize(vec3(0,0,-1)))) - PI_2;
    float angleY = asin(dot(normal, normalize(vec3(0,1,0))));
    
    vec4 base = vec4(1,1,1,1);
    vec4 fragColor = normalToColor(normal, base);
    
    float ratio = min(1.0, dist / MAXDIST);
    ratio = 1.0 - pow(ratio, 5.0);
    fragColor = mix(vec4(0,0,0,0), fragColor, ratio);
    
    return fragColor;
}

vec4 getFragColor(vec2 fragCoord) {
    vec2 uv = (fragCoord - resolution / 2.) / resolution.y;
    
    vec3 camPos = vec3(0.1, 0, 0);
    vec3 ray = normalize(vec3(uv, 1.));
    
    // rotate
    if (false) {
        ray = rotateX(ray, (mouse.y - 0.5) * PI);
        ray = rotateY(ray, (mouse.x - 0.5) * PI);
    } else {
        ray = rotateX(ray, time * 0.1);
        ray = rotateY(ray, time * 0.1);
        ray = rotateZ(ray, time * 0.2);
    }
    
    // translate
    if (true) {
        float iTimeMod = mod(time, 4.0);
        camPos = camPos + 1.0 * vec3(0, iTimeMod * 0.5, iTimeMod);
    }
    
    vec4 normalAndDistance = estimateNormalAndDistance(camPos, ray);
    vec3 normal = normalAndDistance.xyz;
    float dist = normalAndDistance.w;
    
    vec4 fragColor = normalToFinalColor(normal, dist);
    
    //second ray
    if (false && length(normal) > 0.) {
        camPos = camPos + (dist * ray) + (normal * EPSILON * 2.);
        
        normal.x += rand(camPos.xy) / 10.;
        normal.y += rand(camPos.yz) / 10.;
        normal.z += rand(camPos.zx) / 10.;
        
        normalAndDistance = estimateNormalAndDistance(camPos, normal);
        normal = normalAndDistance.xyz;
        dist = normalAndDistance.w;
        
        fragColor = mix(vec4(0,0,0,1), fragColor, pow(min(1.0, dist / 10.), 1. / 5.));
    }
    
    return fragColor;
}

void main(void) {
    glFragColor = getFragColor(gl_FragCoord.xy);
}
