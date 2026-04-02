#version 420

// original https://www.shadertoy.com/view/3sVSWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 check(vec2 uv) {
    return vec3(.02+.02*mod(floor(4.0*uv.x)+floor(4.0*uv.y),2.0));
}

vec4 over( in vec4 a, in vec4 b ) {
    return mix(a, b, 1.-a.w);
}

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y*2.0;
    uv *= 1.25;
    float t = time;
    float rad = .5;
    float thickness = .1;
    float len = length(uv);
       float delta = abs(rad-len);
    float a = smoothstep(.01, .0, delta-thickness);
    vec2 offset = (uv-normalize(uv)*rad)/thickness;
    float nx = clamp(offset.x, -1., 1.);
    float ny = clamp(offset.y, -1., 1.);
    float q = delta/thickness;
    float nz = clamp(sqrt(1.-q*q), 0., a);
    vec3 n = normalize(vec3(nx, ny, nz));
    
    mat2 m0 = rot( t*1.4+.4)*sin(t*.4+.2);
    mat2 m1 = rot(-t*1.4+.7)*sin(t*.6+.5);
    mat2 m2 = rot( t*1.4+.9)*cos(t*.8+.9);

    // light colors
    vec3 l0c = vec3(1., .3, .1);
    vec3 l1c = vec3(.1, .3, 1.);
    vec3 l2c = vec3(.1, 1., .3);
    // light positions
    vec3 l0v = vec3(vec2(.9, 0.)* m0, 2.);
    vec3 l1v = vec3(vec2(.7, 0.)* m1, 2.);
    vec3 l2v = vec3(vec2(0., 1.)* m2, 2.);
    // light intensity
    float li0 = pow(distance(uv, l0v.xy), -1.4);
    float li1 = pow(distance(uv, l1v.xy), -1.4);
    float li2 = pow(distance(uv, l2v.xy), -1.4);

    vec4 c = vec4(.0);
    
    // background
    vec3 check = check(uv);
    c.rgb += check;
    c.rgb += li0*l0c*check*.1;
    c.rgb += li1*l1c*check*.1;
    c.rgb += li2*l2c*check*.1;
    
    // point lightning on torus
    vec3 rc = vec3(.0);
    rc += pow(max(.0, n.z), 2.)*.1; // top ambient
    rc += l0c*pow(max(.0, dot(n, normalize(vec3(l0v.xy-uv, l0v.z-n.z)))), 64.)*.25;
    rc += l1c*pow(max(.0, dot(n, normalize(vec3(l1v.xy-uv, l1v.z-n.z)))), 64.)*.25;
    rc += l2c*pow(max(.0, dot(n, normalize(vec3(l2v.xy-uv, l2v.z-n.z)))), 64.)*.25;
    c = over(vec4(rc, a), c);

    // light dots
    c.rgb += l0c*li0*.002;
    c.rgb += l1c*li1*.002;
    c.rgb += l2c*li2*.002;
   
    // debug normals
    // c = over(vec4(n, a), c);

    glFragColor = c;
}
