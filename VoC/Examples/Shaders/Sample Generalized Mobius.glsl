#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/MlSyRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 ortho(vec2 v)
{
    return vec2(v.y, -v.x);
}

void stroke(float dist, vec3 color, inout vec3 glFragColor, float thickness, float aa)
{
    float alpha = smoothstep(0.5 * (thickness + aa), 0.5 * (thickness - aa), abs(dist));
    glFragColor = mix(glFragColor, color, alpha);
}

void fill(float dist, vec3 color, inout vec3 glFragColor, float aa)
{
    float alpha = smoothstep(0.5*aa, -0.5*aa, dist);
    glFragColor = mix(glFragColor, color, alpha);
}

void renderGrid(vec2 pos, out vec3 glFragColor)
{
    vec3 background = vec3(1.0);
    vec3 axes = vec3(0.4);
    vec3 lines = vec3(0.7);
    vec3 sublines = vec3(0.95);
    float subdiv = 10.0;

    float thickness = 0.003;
    float aa = length(fwidth(pos));

    glFragColor = background;

    vec2 toSubGrid = pos - round(pos*subdiv)/subdiv;
    stroke(min(abs(toSubGrid.x), abs(toSubGrid.y)), sublines, glFragColor, thickness, aa);

    vec2 toGrid = pos - round(pos);
    stroke(min(abs(toGrid.x), abs(toGrid.y)), lines, glFragColor, thickness, aa);

    stroke(min(abs(pos.x), abs(pos.y)), axes, glFragColor, thickness, aa);
}

float sdistLine(vec2 a, vec2 b, vec2 pos)
{
    return dot(pos - a, normalize(ortho(b - a)));
}

float sdistTri(vec2 a, vec2 b, vec2 c, vec2 pos)
{
    return max( sdistLine(a, b, pos),
            max(sdistLine(b, c, pos),
                sdistLine(c, a, pos)));
}

float sdistQuadConvex(vec2 a, vec2 b, vec2 c, vec2 d, vec2 pos)
{
    return max(  sdistLine(a, b, pos),
            max( sdistLine(b, c, pos),
             max(sdistLine(c, d, pos),
                 sdistLine(d, a, pos))));
}

void renderUnitSquare(vec2 pos, inout vec3 glFragColor)
{
#if 0
    // Put a texture in there
    if (pos.x >= 0.0 && pos.y >= 0.0 && pos.x <= 1.0 && pos.y <= 1.0)
    {
        glFragColor.rgb = texture(iChannel0, pos).rgb;
    }
#endif

    float dist = sdistQuadConvex(vec2(0, 0),
                                 vec2(1, 0),
                                 vec2(1, 1),
                                 vec2(0, 1), pos);
    stroke(dist, vec3(0, 0, 1), glFragColor, 0.007, length(fwidth(pos)));
}

void renderAxes(vec2 origin, vec2 pos, inout vec3 glFragColor)
{
    float len = 0.1;
    float thickness = 0.0075;
    float aa = length(fwidth(pos));

    float xshaft = sdistQuadConvex(origin + vec2(0.5*thickness),
                                   origin - vec2(0.5*thickness),
                                   origin + vec2(len, -0.5*thickness),
                                   origin + vec2(len, 0.5*thickness), pos);
    float xhead = sdistTri(origin + vec2(len, -2.0*thickness),
                           origin + vec2(len + 6.0*thickness, 0),
                           origin + vec2(len, 2.0*thickness), pos);

    fill(min(xshaft, xhead), vec3(1, 0, 0), glFragColor, aa);

    float yshaft = sdistQuadConvex(origin - vec2(0.5*thickness),
                                   origin + vec2(0.5*thickness),
                                   origin + vec2(0.5*thickness, len),
                                   origin + vec2(-0.5*thickness, len), pos);
    float yhead = sdistTri(origin + vec2(2.0*thickness, len),
                           origin + vec2(0, len + 6.0*thickness),
                           origin + vec2(-2.0*thickness, len), pos);

    fill(min(yshaft, yhead), vec3(0, 0.75, 0), glFragColor, aa);

}

vec2 cmul(vec2 a, vec2 b)
{
    return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

vec2 csqr(vec2 a)
{
    return cmul(a, a);
}

vec2 cdiv(vec2 a, vec2 b)
{
    return cmul(a, vec2(b.x, -b.y)) / dot(b, b);
}

void main(void)
{
    float aspect = resolution.x / resolution.y;
    vec2 pos = (gl_FragCoord.xy / resolution.y) * 1.5 - vec2((1.5*aspect - 1.0)/2.0, 0.25);

    // apply a generalized Möbius transformation to the plane
#if 0
    // mouse-controlled version
    vec2 urcorner = (mouse*resolution.xy.xy / resolution.xy) * 2.0;
    vec2 b = vec2(0);
    vec2 e = vec2(1, 0);
    vec2 d = cmul(vec2(1,1) - urcorner, vec2(0,1));
    vec2 c = cmul(d, vec2(-0.5, 0.5));
    vec2 a = c + d + e;
    pos = cdiv(cmul(a, pos) + b, cmul(c, csqr(pos)) + cmul(d, pos) + e);
#else
    // animated version
    vec2 a = vec2(1, sin(0.4*time));
    vec2 b = vec2(0);
    vec2 c = vec2(0.3*cos(0.7*time), 0.3*sin(0.5*time));
    vec2 d = vec2(0.3*cos(0.6*time), 0.3*sin(0.8*time));
    vec2 e = vec2(1, 0.5*cos(0.3*time));
    pos -= vec2(0.5);
    pos = cdiv(cmul(a, pos) + b, cmul(c, csqr(pos)) + cmul(d, pos) + e);
    pos += vec2(0.5);
#endif

    // render the grid and stuff
    glFragColor.a = 1.0;
    renderGrid(pos, glFragColor.rgb);
    renderUnitSquare(pos, glFragColor.rgb);
    renderAxes(vec2(0), pos, glFragColor.rgb);
}
