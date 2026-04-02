#version 420

// original https://www.shadertoy.com/view/wtjXWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//====================================
// Quaternion
//====================================
vec4 qmul(vec4 q1, vec4 q2) {
    return vec4(
        q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
        q1.w * q2.w - dot(q1.xyz, q2.xyz)
    );
}

vec3 rotVec(vec3 v, vec4 r) {
    vec4 r_c = r * vec4(-1, -1, -1, 1);
    return qmul(r, qmul(vec4(v, 0), r_c)).xyz;
}

vec4 qaxis(float angle, vec3 axis) {
    float sn = sin(angle * 0.5);
    float cs = cos(angle * 0.5);
    return vec4(axis * sn, cs);
}

//====================================
// Distance functions
//====================================
float dist(vec3 pos)
{
    float d = 2.0 - length(pos.xy);
    float scale = 1.0;
    
    for (int i = 0; i < 10; ++i)
    {
        vec3 p = mod(pos, 8.0) - 4.0;
        d = max(d, ((sin(time + float(i) * 0.3) * 1.5 + 1.0) - length(p.x)) / scale);
        vec4 rot = qaxis(0.8, normalize(vec3(1, 1, 1)));
        rot = qmul(rot, qaxis(time * 0.003 + float(i), vec3(0, 0, 1)));
        pos = rotVec(pos, rot);
        pos *= 1.2;
        scale *= 1.2;
    }
    return d;
}

//====================================
// Normal
//====================================
vec3 calcNormal(vec3 pos)
{
    vec2 ep = vec2(0.01, 0);
    float d0 = dist(pos);
    return normalize(vec3(
        d0 - dist(pos - ep.xyy),
        d0 - dist(pos - ep.yxy),
        d0 - dist(pos - ep.yyx)
    ));
}

//====================================
// Color
//====================================
vec3 calcColor(vec2 uv)
{
    vec4 rot = qaxis(sin(time) * 0.1, vec3(1, 0, 0));
    rot = qmul(rot, qaxis(sin(time * 0.8) * 0.1, vec3(0, 1, 0)));
    rot = qmul(rot, qaxis(time * 0.5, vec3(0, 0, 1)));
    vec3 lightDir = rotVec(normalize(vec3(1, 1, -1)), rot);
    vec3 pos = vec3(0, 0, mod(time, 100.0) * 10.0);
    vec3 dir = rotVec(normalize(vec3(uv, 1)), rot);
    
    for (int i = 0; i < 128; ++i)
    {
        float d = dist(pos);
        if (d < 0.001)
        {
            vec3 albedo = vec3(1, 1, 0.5);
            vec3 norm = calcNormal(pos);
            float atten = max(0.0, dot(norm, lightDir));
            float fog = float(i) / 128.0;
            return mix(atten * albedo, vec3(1.0, 1.0, 1.0), fog);
        }
        pos += d * dir;
    }
    
    return vec3(1, 1, 1);
}

//====================================
// Entry point
//====================================
void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.y;
    glFragColor = vec4(calcColor(uv), 1.0);
}
