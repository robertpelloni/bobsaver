#version 420

// original https://www.shadertoy.com/view/3l33DN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float N11(float n ) {
    return fract(sin(n * 314.21)*521.53);
}

float N21(vec2 n) {
    return N11(n.y+N11(n.x));
}
float N31(vec3 n) {
    return N11(n.z+N11(n.y+N11(n.x)));
}
float ease(float n){
    return n*n*(3.-2.*n);
}
float smoothNoise(vec2 uv, float z) {
    vec2 gv = fract(uv * z);
    vec2 id = floor(uv * z);
    
    float tl = N21(id);
    float tr = N21(id+vec2(1., 0.));
    float bl = N21(id+vec2(0., 1.));
    float br = N21(id+vec2(1., 1.));
    return mix(mix(tl, tr, ease(gv.x)), mix(bl, br, ease(gv.x)), ease(gv.y));
}
float smoothNoise(vec3 xyz, float z) {
    vec3 gv = fract(xyz * z);
    vec3 id = floor(xyz * z);
    
    float ftl = N31(id);
    float ftr = N31(id+vec3(1., 0., 0.));
    float fbl = N31(id+vec3(0., 1., 0.));
    float fbr = N31(id+vec3(1., 1., 0.));
    float front = mix(mix(ftl, ftr, ease(gv.x)), mix(fbl, fbr, ease(gv.x)), ease(gv.y));
    
    float rtl = N31(id+vec3(0., 0., 1.));
    float rtr = N31(id+vec3(1., 0., 1.));
    float rbl = N31(id+vec3(0., 1., 1.));
    float rbr = N31(id+vec3(1., 1., 1.));
    float rear = mix(mix(rtl, rtr, ease(gv.x)), mix(rbl, rbr, ease(gv.x)), ease(gv.y));
    
    return mix(front, rear, ease(gv.z));
}
float noisySphere(vec2 uv, float t) {
    float m = 0.;
    float noise = smoothNoise(vec3(uv,  t),5.);
    float s = .7;
    float a = mix(s*-1., s, noise) *.5 + 1.; 
    uv *= vec2(a);
    m = distance(vec2(.0), uv);
    m = smoothstep(.30, .29, m) - smoothstep(.29, .28, m);
    return m;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= vec2(.5);
    uv.x /= resolution.y/resolution.x;

    // Time varying pixel color
    vec3 col = vec3(0.);
    float m = 0.;
    float z = 10.;

    for(float i = 0.; i<=1.; i+=1./256.) {
        m += noisySphere(uv, i + time * .1) * .025;
    }
    // m = noisySphere(uv, .1);
    col = vec3(m);
    
    // col.rb = suv;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
