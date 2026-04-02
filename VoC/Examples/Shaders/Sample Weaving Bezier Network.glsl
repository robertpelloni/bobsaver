#version 420

// original https://www.shadertoy.com/view/WsGBD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdCapsule( vec2 p, vec2 a, vec2 b, float r )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float cubBez(float x, vec2 cps) {
    return 3.0*(1.0-x)*x*((1.0-x)*cps.x + x*cps.y);
}

/*
    the bezier curve is converted to an axis dependent bezier curve
    the second control point is located at
        vec2(1/3, ts.x)
    and the third
        vec2(2/3, ts.y)
    the first and last are a and b
*/
float cubicBezier(vec2 p, vec2 a, vec2 b, vec2 ts, float D) {
    vec2 ba = b - a;
    vec2 n = vec2(-ba.y, ba.x);
    
    //convert to coordinate system relative to ab
    vec2 q = vec2(dot(p-a, normalize(ba)) / length(ba),
                  dot(p-a, normalize(n)) / length(ba));
    //find distance relative to displace curve
    q.y = q.y + cubBez(q.x, ts);
    
    //return distance
    return sdCapsule(q, vec2(0.0, 0.0), vec2(1.0, 0.0), D);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y + vec2(time/40.0);
    
    float rr = 0.2;
    vec2 ruv = mod(uv, vec2(rr)) / vec2(rr);
    
    float bb = 1.0/3.0;
    float t = bb*sin(time/1.5 + uv.x);
    float q = -bb*sin(time/3.0 + uv.y);
    
    if(mod(uv.x/rr, 3.0) > 2.0) t = -t;
    if(mod(uv.x/rr, 4.0) > 2.0) q = -q;
    if(mod(uv.y/rr, 2.0) > 1.0) t = -t;
    if(mod(uv.y/rr, 6.0) > 5.0) q = -q;
    
    
    float d = 0.0125;
    float w = 0.05;
    vec2 A = vec2(w, w);
    vec2 B = vec2(1.0 - w, w);
    vec2 C = vec2(1.0 - w, 1.0 - w);
    vec2 D = vec2(w, 1.0 - w);
                 
    
    float l = cubicBezier(ruv, A, C, vec2(-t, t), d);
    l = min(l, cubicBezier(ruv, C, A, vec2(-q, -q), d));
    l = min(l, cubicBezier(ruv, B, D, vec2(-t, q), d));
    l = min(l, cubicBezier(ruv, D, B, vec2(-q, t), d));
    l = min(l, length(vec2(0.0) - ruv) - 0.1);
    l = min(l, length(vec2(1.0, 0.) - ruv) - 0.1);
    l = min(l, length(vec2(1.0, 1.) - ruv) - 0.1);
    l = min(l, length(vec2(0.0, 1.) - ruv) - 0.1);

    float a = 1.-60.*l; 
    glFragColor = vec4(l<0.,1,1,1)
                - smoothstep(1.,0.,abs(a)); 
  
}
