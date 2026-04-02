#version 420

// original https://www.shadertoy.com/view/MlKyRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// New Learning Spark
// Heavily based on Martijn Steinrucken's (BigWings) "The Universe Within"
// This is my first attempt at shadertoy coding, first done in 
// Unity 3D 2018.2 as a fullscreen quad shader. ClydeCoulter

#define S(a,b,t) smoothstep(a,b,t)
#define lerp(a, b, t) mix(a, b, t)

// returns a signed vector pependicular to the line a->b whose length is equal to the shortest 
// distance from the line segment a->b to p
vec2 PerpToLine(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p-a; // vector from a to p
    vec2 ba = b-a; // vector from a to b
    float t = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0); // clamping t makes ba a line Segment
    vec2 c = ba*t;
    return pa - c;
}

float DistLine(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p-a; // vector from a to p
    vec2 ba = b-a; // vector from a to b
    float t = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0); // clamping t makes ba a line Segment
    vec2 c = ba*t;
    return length(pa - c);
}

float N21(vec2 p)
{
    p = fract(p * vec2(433.77, 231.93));
    p += dot(p, p + 23.45);
    return fract(p.x*p.y);
}

vec2 N22(vec2 p)
{
    float n = N21(p);
    return vec2(n, N21(p+n));
}

vec2 GetPos(vec2 id, vec2 offset)
{
    vec2 n = N22(id + offset) * (time + 7642.186);

    return offset + sin(n) * 0.4;
}

float Line(vec2 p, vec2 a, vec2 b, float w)
{
    float d = DistLine(p, a, b);
    float m = S(w, w*0.333, d);
    float d2 = length(a-b);
    m *= S(1.2, 0.8, d2)*0.5 + S(0.05, 0.03, abs(d2-0.75));
    return m * 1.5;
}

float Layer(vec2 uv)
{
    float m = 0.0;
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    float w = 0.002;

    vec2 p[9];

    int i = 0;
    for (float y = -1.0; y <= 1.0; y++)
    {
        for (float x = -1.0; x <= 1.0; x++)
        {
            p[i] = GetPos(id, vec2(x,y));
            i++;
        }
    }

    float t = (time + 123.67)*10.0;

    for (int ndx = 0; ndx < 9; ndx++)
    {
        m += Line(gv, p[4], p[ndx], w);

        vec2 j = (p[ndx] - gv) * 25.0;
        float sparkle = 1.0/dot(j,j);
        m += sparkle * (sin(t+fract(p[ndx].x)*10.0) * 0.8 + 0.4);
    }

    // Pulse across to neighbors
    // Note: I think these pulses could be implemented
    // in the loop above, and all neighbors could pulse to
    // one another....but I haven't worked it all out yet.
    float speed = time * 0.9;
    vec2 pulse = vec2(0.0);
    float pw = w*16.0;
    pulse = lerp(p[4], p[1], clamp(mod((speed + N21(id)*3.0), 3.0) - 2.0, 0.0, 1.0));
    m += S(pw, 0.0, length(gv - pulse)) * 2.5;
    pulse = lerp(p[4], p[3], clamp(mod((speed + N21(id)*3.5), 3.0) - 2.0, 0.0, 1.0));
    m += S(pw, 0.0, length(gv - pulse)) * 2.5;
    pulse = lerp(p[4], p[5], clamp(mod((speed + N21(id)*4.0), 3.0) - 2.0, 0.0, 1.0));
    m += S(pw, 0.0, length(gv - pulse)) * 2.5;
    pulse = lerp(p[4], p[7], clamp(mod((speed + N21(id)*4.5), 3.0) - 2.0, 0.0, 1.0));
    m += S(pw, 0.0, length(gv - pulse)) * 2.5;

    // pull neighbor pulses across the last half
    pulse = mix(p[1], p[4], clamp(mod((speed + N21(vec2(id.x, id.y-1.0))*4.5), 3.0) - 2.0, 0.0, 1.0));
    m += S(pw, 0.0, length(gv - pulse)) * 2.5;
    pulse = mix(p[3], p[4], clamp(mod((speed + N21(vec2(id.x-1.0, id.y))*4.0), 3.0) - 2.0, 0.0, 1.0));
    m += S(pw, 0.0, length(gv - pulse)) * 2.5;
    pulse = mix(p[5], p[4], clamp(mod((speed + N21(vec2(id.x+1.0, id.y))*3.5), 3.0) - 2.0, 0.0, 1.0));
    m += S(pw, 0.0, length(gv - pulse)) * 2.5;
    pulse = mix(p[7], p[4], clamp(mod((speed + N21(vec2(id.x, id.y+1.0))*3.0), 3.0) - 2.0, 0.0, 1.0));
    m += S(pw, 0.0, length(gv - pulse)) * 2.5;

    // draw lines that cross our cells boundary
    // where two neighbor points could draw across this cell
    m += Line(gv, p[1], p[3], w);
    m += Line(gv, p[1], p[5], w);
    m += Line(gv, p[7], p[3], w);
    m += Line(gv, p[7], p[5], w);

    return m;
}

float GetLayers(vec2 uv)
{
    float m = 0.0;

    float t = time * 0.015; // speed that we move through the layers
    for (float i = 0.0; i < 1.0; i += 1.0/3.0)
    {
        float z = fract(i+t);
        float size = mix(10.0, 0.3, z);
        float fade = S(0.0, 0.5, z) * S(1.0, 0.85, z); // fade in then fade out near camera(0)
        m += Layer(uv * size + i * 10.0) * fade;
    }

    return m;
}

// Attempt to create offsets (for glass effect) instead of a mask (CFC,Jr)

vec2 LineOffset(vec2 p, vec2 a, vec2 b, float w)
{
    //float d = DistLine(p, a, b);

    // Let's try all of that again

    vec2 perp = PerpToLine(p, a, b); // returns vector offset from line segment a->b to p

    float d = length(perp);
    float m = S(w, w*0.7, d); // mask line to width

    float d2 = length(a-b);
    //m *= S(1.2, 0.8, d2)*0.5 + S(0.05, 0.03, abs(d2-0.75));

    return 160.0 * abs(perp) * perp * m;
}

vec2 LayerOffset(vec2 uv)
{
    vec2 m = vec2(0.0);
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    float w = 0.04;

    vec2 p[9];

    int i = 0;
    for (float y = -1.0; y <= 1.0; y++)
    {
        for (float x = -1.0; x <= 1.0; x++)
        {
            p[i] = GetPos(id, vec2(x,y));
            i++;
        }
    }

    float t = (time + 123.67)*10.0;

    for (i = 0; i < 9; i++)
    {
        if (i != 4)    
            m += LineOffset(gv, p[4], p[i], w);
    }
    // draw lines that cross our cells boundary
    // where the two neighbor points crossing lines in this cell
    m += LineOffset(gv, p[1], p[3], w);
    m += LineOffset(gv, p[1], p[5], w);
    m += LineOffset(gv, p[7], p[3], w);
    m += LineOffset(gv, p[7], p[5], w);

    //if (gv.x > 0.485 || gv.y > 0.49)
    //    m = vec2(1,1);

    return m;
}

vec3 GetLayerDistortion(vec2 uv)
{
    vec2 m = vec2(0,0);
    float fade;
    float t = time * 0.015; // speed that we move through the layers
    for (float i = 0.0; i < 1.0; i += 1.0/3.0)
    {
        float z = fract(i+t);
        float size = mix(10.0, 0.3, z);  // *** Layer Size!
        fade = S(0.0, 0.5, z) * S(1.0, 0.9, z); // fade in then fade out near camera(0)
        m += LayerOffset(uv * size + i * 10.0) * fade; 
    }

    return vec3(m, fade);
}

vec3 GetBackground(vec2 uv)
{
    vec3 c = vec3(0,0,0);

    // make a dotted background
    float scale = 50.0;
    vec2 pv = fract(uv * scale) - 0.5;
    vec2 id = floor(uv * scale);
    float blink = max(0.0, sin(time*12.0*N21(vec2(id.x*5.83, id.y*1.23)))) * 1.1 + 0.5;
    float r = N21(id*1.236);
    float g = N21(id*33.277);
    float b = N21(id*78.29);
    float m = S(0.45, 0.0, length(pv));
    c +=  m * vec3(r, g, b) * blink;

    return c;
}

// The original version of this shader was taken from 
// Martijn Steinruken's "Universe Within".
// I intend to modify it such that the elements refract 
// light from glowing sphere's that dance throughout.
// And, it seems that I have accomplished that goal
// to some degree. (CFC,jr)

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec2 auv = uv;
    float gradient = uv.y;

    // sway and rotate with time
    float t = sin(mod((time * 0.1 + 3487.4), 6.28318530717959));  // rotate time
    float st = sin(t);
    float ct = cos(t);

    mat2 rot = mat2(ct, -st, st, ct);
    uv = rot * uv;
    uv += vec2(-st, -ct) * 1.0;

    // distortion is added for glass effect

    vec3 distort = GetLayerDistortion(uv);
    uv -= distort.xy * 1.0;

    // Get Color Masks
    vec3 col = vec3(0,0,0);

    col += GetLayers(uv) * 2.0 * vec3(1.0, 0.9, 0.5);

    col += GetBackground(uv);
    
    // Time varying pixel color

    // Output to screen
    glFragColor = vec4(col,1.0);
}
