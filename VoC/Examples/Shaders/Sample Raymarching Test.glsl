#version 420

// original https://www.shadertoy.com/view/3llfWM

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

float sineCrazy(vec3 p){
    return (sin(p.x) + sin(p.y) + sin(p.z)) / 3.0;
}

float sphere(vec3 p){
    return length(p) - 0.75;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float scene(vec3 p){
    vec3 p1 = rotate(p, vec3(1.0), time);
    
    float scale = 10.0 + 10.0 * abs(sin(time * 0.5));
    
    return max( sphere(p), sineCrazy(p1 * scale) / scale );
}

vec3 getNormal(vec3 p){
    vec2 o = vec2(0.001, 0.0);
    
    return normalize(vec3( 
        scene(p + o.xyy) - scene(p - o.xyy),
        scene(p + o.yxy) - scene(p - o.yxy),
        scene(p + o.yyx) - scene(p - o.yyx)
    ));
    
}

vec3 getColor(float amount){
    vec3 col = 0.5 + 0.5 * cos(6.28318530718 * (vec3(0.2, 0.0, 0.0) + amount * vec3(1.0, 1.0, 0.5)));
    return col * amount;
}

vec3 getColorAmount(vec3 p){
    float amount = clamp((1.5 - length(p)) / 2.0, 0.0, 1.0);
    vec3 col = 0.5 + 0.5 * cos(6.28319 * (vec3(0.2, 0.0, 0.0) + amount * vec3(1.0, 1.0, 0.5)));
    return col * amount;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy - 0.5;
    
    uv.x *= resolution.x / resolution.y;
    
    vec3 camPos = vec3(0.0, 0.0, 2.);
    
    vec3 ray = normalize(vec3(uv, -1.0));
    
    vec3 rayPos = camPos;
    
    vec3 light = vec3(-1.0, 1.0, 1.0);
    
    float curDist = 0.0;
    float rayLen = 0.0;
    
    vec3 color = vec3(0.0);
    
    for(int i = 0; i <= 64; i++){
        curDist = scene(rayPos);
        rayLen += 0.6 * curDist;
        
        rayPos = camPos + ray * rayLen;

        color += 0.2 * vec3(getColorAmount(rayPos));
    }
    
    
    // Output to screen
    glFragColor = vec4(color,1.0);
}
