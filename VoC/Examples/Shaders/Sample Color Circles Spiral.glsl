#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// maybe return a color
vec4 circle(vec2 position, float radius, vec2 currentPosition, float offsetColor) {
    vec2 p = currentPosition - position;
    float length = sqrt(p.x*p.x + p.y*p.y);

    if(length <= radius) {
        float color = 1.0 - length / radius;

        //return vec4(1.0, 1.0, 1.0, 0.1);
        return vec4(vec3(hsv2rgb(vec3(mod(offsetColor + color, 1.0), 1.0, 1.0))), 0.8);
    } else {
        return vec4(0.0, 0.0, 0.0, 0.1);
    }
}

vec4 line(vec2 position) {
    float distance = abs(0.25 - position.y);
    float glow = 0.01;

    if(distance <= glow) {
        float color = clamp(distance / glow, 0.0, 1.0);
        return vec4(color, 0.0, 0.0, 0.25);

    }

    return vec4(0.0, 0.0, 0.0, 0.0);
}

vec4 ring(vec2 ringPosition, vec2 position, float r1, float r2, float col) {
    vec2 p = ringPosition - position;
    float length = sqrt(p.x * p.x + p.y * p.y);

    float mi = min(r1, r2);
    float ma = max(r1, r2);
    if(length >= mi && length <= ma) {
        return vec4(hsv2rgb(vec3(mod(col + length / ma, 1.0), 1.0, 1.0)), 0.60);
        //return vec4(1.0, 0.0, 0.0, 1.0);
    } else {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
}

void main(void) {

    vec2 position = gl_FragCoord.xy;
    position.x /= resolution.x;
    position.y /= resolution.x;

    vec4 color = vec4(0.0, 0.0, 0.0, 0.0);

    vec2 center = vec2(0.5, 0.4);
    const int numCircles = 200;

    float r = 0.1;
    float angle = 0.0;
    for(int i = 0; i < numCircles; ++ i) {

        angle += 0.06 * time;
        r = float(i) / float(numCircles) * 0.6;
        vec2 pos = center;
        pos.x += r * cos(angle);
        pos.y += r * sin(angle);
        color += circle(pos, 0.1 * abs(cos(time * 0.1)), position, sin(time));
    }

    glFragColor = normalize(color);
}
