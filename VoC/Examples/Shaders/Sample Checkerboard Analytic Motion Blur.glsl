#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlcXRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// Analytic Linear Motion Blur Series:
//
// Self-Intersecting Polygon (XOR Rule) - https://www.shadertoy.com/view/tltXRS
// Concave Polygon - https://www.shadertoy.com/view/tldSzS
// Square - https://www.shadertoy.com/view/wtcSzB
// Checkerboard - https://www.shadertoy.com/view/tlcXRX
//

vec2 cameraTransformation(vec2 p, float t)
{
    float a = t * 2. + sin(-t) * 1.5;
    mat2 r = mat2(cos(a), sin(a), -sin(a), cos(a));
    return (r * (p - vec2(cos(t / 2.), sin(t / 3.))) * 5. / pow(2., 1. + cos(t)));
}

float integrateCheckerboard(vec2 uv0, vec2 uv1)
{
      vec2 rd = uv1 - uv0;
    
    vec2 dt = abs(vec2(1) / rd);
    vec2 t = (floor(uv0) + max(sign(rd), 0.) - uv0) * dt * sign(rd);
    int e = int(floor(uv0.x) + floor(uv0.y)) & 1;
    
    float mt = 0., pt, a = 0.;
    
    for(int i = 0; i < 8; ++i)
    {
        pt = mt;
        mt = min(t.x, t.y);
        
        if((i & 1) == e)
            a += min(1., mt) - pt;

        if(mt > 1.)
            break;
        
        t += step(t, t.yx) * dt;
    }
    
    return a;
}

float tri(float x)
{
    return abs(fract(x / 2. + .5) - .5) * 2.;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / resolution.y * 2.;
    
    vec2 uv2 = uv;

    if(uv.x < 0.)
        uv.x += resolution.x / resolution.y;
    
    float t1 = time, t0 = time - 1. / 30.;
    
    vec2 uv0 = cameraTransformation(uv, t0);
    vec2 uv1 = cameraTransformation(uv, t1);
    
    vec3 col = vec3(0);

    float a = 0.;
    
    if(uv2.x < 0.)
    {
        // Product of integrals
          vec2 d = uv1 - uv0;
        vec2 b = vec2(tri(uv1.x) - tri(uv0.x), tri(uv1.y) - tri(uv0.y)) / d;

        a = b.x * b.y * .5 + .5;
    }
    else
    {
        // Integral of products
        a = integrateCheckerboard(uv0, uv1);
    }
    
    col = mix(vec3(.1), vec3(.9), a);
    
    col = mix(col, vec3(1., .2, .1), step(abs(uv2.x), .01));

    glFragColor = vec4(pow(col, vec3(1. / 2.2)),1.0);
}
