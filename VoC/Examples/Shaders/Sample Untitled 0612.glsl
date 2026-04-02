#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    const float span = 5.;
    const float r = span / 2.;
    vec3 color;
    vec2 uv = (gl_FragCoord.xy * 2. - resolution) / resolution.y;
    uv *= 250.;
    float zt = -9e9;
    float zb = 9e9;

    for (float y = -180.; y <= 180.; y += span) {
        float x = (floor(uv.x / span) + .5) * span + y / 2.;
        if (abs(x) > 180.) continue;

        float t = radians(length(vec2(x, y)));
        t *= sin(time * .2) * 3.;
//        t -= time;
        float z = (cos(t) * 100. - cos(t * 3.) * 30.) + y / 2.;
        vec2 p = vec2(x - y / 2., z);
        float d = distance(uv, p) / r - 1.;
        if (d <= 0.) {
            if (z < zb || zt < z) {
                color = vec3(1, 2, 0) * -d;
            }
            break;
        }
        zt = max(zt, z);
        zb = min(zb, z);
    }
    glFragColor = vec4(color, 1);
}
