#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 onRep(vec2 p, float interval) {
    return mod(p, interval) - interval * 0.5;
}

float barDist(vec2 p, float interval, float width) {
    return length(max(abs(onRep(p, interval)) - width, 0.0));
}

float tubeDist(vec2 p, float interval, float width) {
    return length(onRep(p, interval)) - width;
}

vec3 rotate(vec3 p, float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

float sceneDist(vec3 p) {
    float bar_x = barDist(p.yz, 1., 0.1);
    float bar_y = barDist(p.xz, 1., 0.1);
    float bar_z = barDist(p.xy, 1., 0.1);

    float tube_x = tubeDist(p.yz, 0.1, 0.025);
    float tube_y = tubeDist(p.xz, 0.1, 0.025);
    float tube_z = tubeDist(p.xy, 0.1, 0.025);

    return max(max(max(min(min(bar_x, bar_y),bar_z), -tube_x), -tube_y), -tube_z);
}

void main( void ) {
    vec2 p = ( gl_FragCoord.xy * 2. - resolution.xy ) / min(resolution.x, resolution.y);

    vec3 cameraPos = vec3(0., 0., time * 0.5);
    vec3 cameraTarget = vec3(1., 0.5, time * 0.5);

    float screenZ = 2.5;
    vec3 rayDirection = rotate(normalize(vec3(p, screenZ)), radians(time * 10.), vec3(0.0, 0.0, 1.));

    float depth = 0.0;
    vec3 col = vec3(1.0);

    for (int i = 0; i < 99; i++) {
        vec3 rayPos = cameraPos + rayDirection * depth;
        float dist = sceneDist(rayPos);

        if (dist < 0.0001) {
            col = vec3(.3, 0.9, 0.7) * (0.2 + float(i) / 100.0);
            break;
        }

        depth += dist;
    }

    glFragColor = vec4(col, 1.);
}
