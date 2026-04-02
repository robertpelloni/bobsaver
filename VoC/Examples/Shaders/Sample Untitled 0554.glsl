#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
    mat4 m = rotationMatrix(axis, angle);
    return (m * vec4(v, 1.0)).xyz;
}

float sphere(vec3 p, float s) { 
    return length(p) - s; 
}

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float scene(vec3 p) {
    vec3 rot = rotate(p, vec3(0.5, -0.5, 0.2), time);
    float box = sdBox(rot, vec3(0.5,0.5,0.5));
    float sphere = sphere(p + vec3((1. - mouse.x - 0.5)*.3, 1.0-mouse.y - 0.5, 0.), 0.7);
    return smin(box, sphere, 0.5);
}

vec3 getNormal(vec3 p) {
    vec2 o = vec2(0.001, 0.0);
    return normalize(vec3(
            scene(p + o.xyy) - scene(p - o.xyy),
            scene(p + o.yxy) - scene(p - o.yxy),
            scene(p + o.yyx) - scene(p - o.yyx)
    ));
}

void main(void) {

    vec2 p = (gl_FragCoord.xy*2. - resolution) / resolution.y;

    vec3 camPos = vec3(0.0, 0.0, 2.0);
    vec3 ray = normalize(vec3(p, -1.0));
    vec3 light = vec3(0.5, 0.5,0.4);

    bool hit = false;
    float curDist = 0.0;
    float rayLen = 0.0;
    vec3 rayPos = camPos;
    
    for(int i = 0; i<8; i++) {
        curDist = scene(rayPos);
        rayLen = rayLen + curDist;
        rayPos = camPos + ray*rayLen;
        if(abs(curDist)< 0.01) {
            hit = true;
            break;
        }
    }
    

    vec3 n = getNormal(rayPos);
    float diff = dot(light, n);
    
    glFragColor = vec4(vec3(n), 1.0);
}
