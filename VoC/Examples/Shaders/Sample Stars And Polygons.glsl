#version 420

// original https://www.shadertoy.com/view/ldGcDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415927;

float smoothfill(in float a, in float b, in float epsilon)
{
    // A resolution-aware smooth edge for (a < b)
    return smoothstep(0., epsilon / resolution.y, b - a);
}

float disc(in vec2 uv, in float radius)
{
    // Function for a circular disc
    return smoothfill(length(uv), radius, 10.);
}

float box(in vec2 uv, in vec2 size)
{
    // Function for an axis-aligned rectangle
    // We have to do this independently for x- and y-direction to get smooth edging correct
    vec2 t = abs(uv / size);
    return smoothfill(t.x, 1., 10. / size.x) * smoothfill(t.y, 1., 10. / size.y);
}

float polygon(vec2 uv, in int sides, in float size, in float rotation)
{
    // Function for an N-sided regular polygon
    float repeat = PI / float(sides);
    float theta = atan(uv.x, uv.y) + rotation;
    float t = cos(repeat - mod(theta, repeat * 2.)) * length(uv) / cos(repeat);
    return smoothfill(t, size, 10.);
}

float curved(vec2 uv, in int points, in float size)
{
    // Function for an N-pointed star approximation that produces curved edges
    float repeat = 2. * PI / float(points);
    float theta = atan(uv.x, uv.y);
    float t = cos(repeat - mod(theta, repeat) * 2.) * length(uv) / cos(repeat);
    return smoothfill(t, size, 50.);
}

float straight(vec2 uv, in int points, in float size)
{
    // Function for an N-pointed star with straight edges
    float repeat = 2. * PI / float(points);
    float theta = abs(mod(atan(uv.x, uv.y) + repeat * 0.5, repeat) - repeat * 0.5) - repeat;
    float t = cos(theta) * length(uv) / cos(repeat);
    return smoothfill(t, size, 25.);
}

float star(vec2 uv, in int points, in float outer, in float inner, in float rotation)
{
    // Function for a fully-specified N-pointed star
    float repeat = PI / float(points);
    float theta = atan(uv.x, uv.y) + rotation;
    float t1 = cos(repeat - mod(theta, repeat * 2.));
    float t2 = cos(repeat - mod(theta + repeat, repeat * 2.));
    float t = (t1 * outer - t2 * (outer - inner)) * length(uv) / (cos(repeat) * outer - (outer - inner));
    return smoothfill(t, outer, 25.);
}

float golf(vec2 uv, in float size)
{
    // Short function for a 5-pointed star
    float t = cos(abs(fract(atan(uv.x, uv.y) * .8 + .5) - .5) / .8 - 1.26) * length(uv) / .3;
    return smoothfill(t, size, 33.);
}

void main(void)
{
    // Normalized pixel coordinates (from -1 to 1)
    const int ROWS = 3;
    const int COLUMNS = 4;
    const float GAP = 0.1;
    vec2 uv = gl_FragCoord.xy / resolution.y;
    uv.x -= (resolution.x / resolution.y - float(COLUMNS) / float(ROWS)) * 0.5;
    vec3 col = vec3(0.1);
    uv = uv * (float(ROWS) + GAP) - GAP;
    if ((uv.x >= 0.) && (uv.y >= 0.) && (uv.x < float(COLUMNS)))
    {
        ivec2 iuv = ivec2(uv);
        uv = fract(uv) * (2. + GAP * 2.) - 1.;
        if (max(abs(uv.x), abs(uv.y)) < 1.)
        {
            int panel = iuv.x + iuv.y * COLUMNS;
            float size1 = sin(time + float(panel)) * 0.4 + 0.6;
            float size2 = sin(time * 0.7 + float(panel)) * 0.3 + 0.7;
            switch (panel)
            {
                case 0:
                    col = vec3(1,0,0) * disc(uv, size1);
                    break;
                case 1:
                    col = vec3(0,1,0) * box(uv, vec2(size1, size2));
                    break;
                case 2:
                    col = vec3(1,1,0) * polygon(uv, 5, size1, 0.);
                    break;
                case 3:
                    col = vec3(0,0,1) * polygon(uv, 6, size2, time);
                    break;
                case 4:
                    col = vec3(1,0,1) * curved(uv, 5, size1);
                    break;
                case 5:
                    col = vec3(0,1,1) * curved(uv, 6, size2);
                    break;
                case 6:
                    col = vec3(1,0,0) * straight(uv, 5, size1);
                    break;
                case 7:
                    col = vec3(0,1,0) * straight(uv, 6, size2);
                    break;
                case 8:
                    col = vec3(1,1,0) * star(uv, 5, size1, size1 * 0.382, 0.);
                    break;
                case 9:
                    col = vec3(0,0,1) * star(uv, 6, size2, size1, 0.);
                    break;
                case 10:
                    col = vec3(1,0,1) * star(uv, 7, 0.6, size1, time);
                    break;
                case 11:
                    col = vec3(0,1,1) * golf(uv, size1);
                    break;
                default:
                    col = vec3(0);
                    break;
            }
        }
    }

    // Output to screen
    glFragColor = vec4(col, 1);
}
