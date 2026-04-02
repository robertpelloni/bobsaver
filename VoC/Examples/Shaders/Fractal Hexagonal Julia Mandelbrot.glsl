#version 420

// original https://www.shadertoy.com/view/3dlBRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITER 256

float hexDist(vec2 p) {
    p = abs(p);
    float c = dot(p, normalize(vec2(1, 1.73)));
    c = max(c, p.x);
    return c;
}

vec3 gradient(in float r) {    
    r /= 30.;
    r = pow(min(r, 1.), 0.5);
    vec3 rainbow = 0.5 + 0.5 * cos((0.8 + 5. * r + vec3(0.2, 0.45, 0.5)*6.));
    
    return rainbow;
}

vec3 fractal(vec2 z, vec2 c) {
    for (int i = 0; i < ITER; ++i) {
        z = vec2(
            z.x*z.x - z.y*z.y + c.x,
            2.0 * z.x*z.y + c.y
        );

        float distSqr = dot(z, z);
        
        if (distSqr > 20.0)
            return gradient(float(i) + 1.0 - log2(log(distSqr) / 2.0));
    }
    
    return vec3(0.0, 0.0, 0.0);
}

vec4 hexCoords(vec2 uv) {
    // x is theta
    // y is r
    // z & w is id
    vec2 r = vec2(1, 1.73);
    vec2 h = r*.5;
   
    
    vec2 a = mod(uv, r)-h;
    vec2 b = mod(uv-h, r)-h;
    
    vec2 gv = dot(a, a) < dot(b,b) ? a : b;
    
    float x = atan(gv.x, gv.y);
    float y = .5 - hexDist(gv);
    vec2 id = uv - gv;
    return vec4(x, y, id.x, id.y);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / resolution.y;

    float t = mod(time, 16.);
    t = min(t, 16. - t);
    
    
    float zoom = 0.3 + pow(smoothstep(0., 6., t) * 2., 2.);
    
    uv -= vec2(0.25, 0.);
    
    uv *= 6. * zoom;
    
    vec4 hc = hexCoords(uv);
    
    
    vec2 z = uv - hc.zw;
    z *= 2.5;
    
    
    float scale = 0.4 / zoom;
 
    
    vec2 c = scale * hc.zw;
    vec2 cSmooth = scale * uv;
    
    
    vec3 julia = fractal(z, c);
    vec3 mandel = fractal(cSmooth, cSmooth);
    
    float mixV = 0.6 * smoothstep(6., 7., t);
    
    glFragColor.xyz = mix(julia, mandel, mixV);
    
    
    glFragColor *= max(smoothstep(0., 0.002 / zoom, hc.y), mixV);

}
