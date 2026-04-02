#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

// mazey

// hash without sine
// https://www.shadertoy.com/view/4djSRW
#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
float hash13(vec3 p3) {
    p3  = fract(p3 * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float map(vec3 p) {
    
    vec3 p2 = p+vec3(p.y, -p.x, 0.);
    
    return
        float(
            hash13(floor(p2))<.5 ?
            2. * abs(fract(p.x)-.5) :
            2. * abs(fract(p.y)-.5)
        );
    
}

void main() {
    vec2 res = resolution.xy;
    vec2 p = (gl_FragCoord.xy-res/2.) / res.y;
    float f = 0.;
    
    vec3 cpos = vec3(0.);
    vec3 cdir = 4. * vec3(p, 1.);
    
    cpos.x += time;
    
    float alpha = 1.;
    const float I = 8.;
    for(float i = 1.; i<=I; i++) {
        cpos += cdir;
        float m = map(cpos) + .13;
        alpha -= 1.-step(.5, m);
        if(alpha<=0.)
            break;
        f = mix(f, pow(m, .25)*i/I, alpha);
    }
    
    glFragColor = vec4(vec3(f)*vec3(1.5, 1.2, 1.), 1.);
}
