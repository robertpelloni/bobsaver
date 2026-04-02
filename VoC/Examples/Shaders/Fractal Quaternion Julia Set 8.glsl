#version 420

// original https://www.shadertoy.com/view/tt2fRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 cameraPosition;
mat3 cameraMatrix;
vec4 offset;
void qFold (inout vec4 a) {
    a = vec4(a.x*a.x-a.y*a.y-a.z*a.z-a.w*a.w,2.0*a.x*a.y,2.0*a.x*a.z,2.0*a.x*a.w);
}
float map (vec3 pos) {
    vec4 z = vec4(pos.xyz, 0.0);
    float md2 = 1.0;
    float radius2 = dot(z, z);
    for (int i = 0; i < 25; i ++) {
        qFold(z);
        z += offset;
        md2 *= 4.0 * radius2;
        radius2 = dot(z, z);
        if (radius2 > 4.0) break;
    }
    return 0.25 * sqrt(radius2 / md2) * log(radius2) - 0.001;
}
vec3 xDir = vec3(0.000001, 0, 0);
vec3 yDir = vec3(0, 0.000001, 0);
vec3 zDir = vec3(0, 0, 0.000001);
vec3 surfaceNormal (vec3 pos) {
    vec3 normal = vec3(
        map(pos + xDir) - map(pos - xDir),
        map(pos + yDir) - map(pos - yDir),
        map(pos + zDir) - map(pos - zDir)
    );
    return normalize(normal);
}
vec3 lightDirection;
float hue;
vec3 tint;
vec3 trace (vec3 origin, vec3 direction) {
    float totalDistance = 0.0;
    for (float steps = 0.0; steps < 100.0; steps ++) {
        vec3 pos = origin + direction * totalDistance;
        float distance = map(pos);
        totalDistance += distance;
        if (dot(pos, pos) > 25.0) break;
        if (distance < 0.002) {
            vec3 normal = surfaceNormal(pos);
            float diffuse = max(-dot(normal, lightDirection), 0.0);
            float specular = -dot(reflect(direction, normal), lightDirection);
            specular = max(pow(specular, 5.0), 0.0);
            float shade = diffuse * 0.7 + specular * 0.3;
            return shade * tint;
        }
    }
    return vec3(0.1);
}

void main(void)
{
    cameraPosition = 1.8 * vec3(cos(time), 0, sin(time));
    cameraMatrix = mat3(cos(time+3.14/2.0), 0, -sin(time+3.14/2.0), 0, 1, 0, sin(time+3.14/2.0), 0, cos(time+3.14/2.0));
    offset = vec4(cos(time), sin(time), cos(time * 2.0 + 3.14), sin(time * 1.61 + 3.14)) * 0.6;
    lightDirection = vec3(cos(time + 3.14), 0.0, sin(time + 3.14));
    tint = vec3(cos(time / 20.0 * 3.1415 * 2.0) + 1.0, cos(time / 20.0 * 3.1415 * 2.0 + 2.0 * 3.1415 / 3.0) + 1.0, cos(time / 20.0 * 3.1415 * 2.0 + 4.0 * 3.1415 / 3.0) + 1.0) / 2.0;
    hue = time / 20.0;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 1.0 - 2.0 * gl_FragCoord.xy/resolution.xy;
    vec3 ray = normalize(vec3(uv, 1.0)) * cameraMatrix;

    // Time varying pixel color
    vec3 col = trace(cameraPosition, ray);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
