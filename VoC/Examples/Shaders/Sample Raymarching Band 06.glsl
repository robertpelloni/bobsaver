#version 420

// original https://www.shadertoy.com/view/WtlSRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 path(float z){
    float x = sin(z) + 2.0 * cos(z * 0.3) - 1.5 * sin(z * 0.12345);
    float y = cos(z) + 1.5 * sin(z * 0.3) + 2.0 * cos(z * 0.12345);
    return vec2(x,y);
}

float map(vec3 p){
    p = fract(p/2.0) * 6.0 - 3.0;
    vec2 o = path(p.z) / 4.0;
    float tBase = max(-length(p.xy - o) + 1.0 
                      //* (1.0 + sin(p.z) * 0.5)
                      ,length(p.xy - o) - 1.2 
                      //* (1.0 + sin(p.z) * 0.5)
                     );
    float tdonut = max(-length(p.xy - o) + 0.5
                      ,length(p.xy - o) - 0.6 
                     );
    tdonut = max(tdonut,abs(fract(p.z) - 0.5));
    float tTube1 = length(p.xy - o + vec2(0.3,0.3)) - 0.025;
    float tTube2 = length(p.xy - o + vec2(0.5,0.2)) - 0.025;
    float tTube3 = length(p.xy - o + vec2(0.2,0.5)) - 0.025;    
    float tTube4 = length(p.xy - o + vec2(-0.3,-0.3)) - 0.025;
    float tTube5 = length(p.xy - o + vec2(-0.5,-0.2)) - 0.025;
    float tTube6 = length(p.xy - o + vec2(-0.2,-0.5)) - 0.025;
    float tTube = min(min(tTube1,tTube2),tTube3);
    tTube = min(min(tTube,tTube4),min(tTube5,tTube6));

    float bound = 2.0;
    float tSplit = (fract(p.z)-0.5);
    tSplit = min(tSplit, abs((p.x - o.x))-0.15);
    tSplit = min(tSplit, abs((p.y - o.y))-0.15);

    return min(min(max(tBase,-tSplit),tdonut),tTube);
}
const float EPS = 0.001;
vec3 getNormal(vec3 p) {
    return normalize(vec3(
        map(p + vec3(EPS, 0.0, 0.0)) - map(p + vec3(-EPS,  0.0,  0.0)),
        map(p + vec3(0.0, EPS, 0.0)) - map(p + vec3( 0.0, -EPS,  0.0)),
        map(p + vec3(0.0, 0.0, EPS)) - map(p + vec3( 0.0,  0.0, -EPS))
    ));
}

vec4 trace (vec3 o, vec3 r){
    float t = 0.0;
    vec3 p = vec3(0.0,0.0,0.0);
    
    for(int i = 0; i < 32; ++i){
        p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    return vec4(getNormal(p),t);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    float PI = 3.14159265;
    vec2 uv = gl_FragCoord.xy /resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 r = normalize(vec3(uv,0.5));

    float z = time * 4.0 ;
    
    r.xy *= mat2( sin(time),cos(time),
                    -cos(time),sin(time));
    vec2 a = path(z);
    vec3 o = vec3(a / 4.0,z);
    vec4 data = trace(o,r);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.1);
    vec3 fc = mix(vec3(0.5 - data.x,0.5 -data.y,0.5-data.z),vec3(1),1.0 - fog);
    //fc = vec3(fog);
    // Output to screen
    glFragColor = 1.0-vec4(fc,1.0);
}
