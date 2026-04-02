#version 420

// original https://www.shadertoy.com/view/Wty3Rw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,c) smoothstep(a,b,c)
#define M_PI 3.1415926535897932384626433832795

vec2 rot(vec2 xy, float phi) {
    return vec2(xy.x*cos(phi) - xy.y*sin(phi), xy.y*cos(phi) + xy.x*sin(phi));
}

float gear(vec2 uv, float t) {
    uv -= 0.5;
    float phi = atan(uv.y,uv.x) + t;
    float d = length(uv);
    
    float od = 0.495;
    
    uv = rot(uv,t);
    
    float g = 0.;
    g -= S(0.17,0.165,length(uv - vec2(0.,0.25)));
    g -= S(0.17,0.165,length(uv - vec2(0.25,0.)));
    g -= S(0.17,0.165,length(uv + vec2(0.,0.25)));
    g -= S(0.17,0.165,length(uv + vec2(0.25,0.)));
    g += S(od+0.005,od,d + atan(sin(20.*phi)*4.)/40.);
    
    g = min(g,1.);
    
    return g;
}

float layer(vec2 uv, float t) {
    float l = 0.;
    vec2 id = floor(uv);
    uv = fract(uv);
    
    for (float i = -1.; i <= 1.; i++)
        for (float j = -1.; j <= 1.; j++) {
            vec2 sn = mod(id + vec2(i,j),2.)*2. - 1.;
            l = mix(l, 1., gear(uv + vec2(i,j), sn.x*sn.y*t));
        }
    return l;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - resolution.xy/2.0)/resolution.y;
    uv*=.5;

    float t = time/2.;
    
    float zoom_pow = 2.;
    float z = pow(zoom_pow,fract(t));
    uv/=z;
    
    uv = rot(uv,t/2.);
    
    vec4 col = vec4(0);
    
    float fade = 0.6;
    float N = 5.;
    
    uv*=pow(zoom_pow,N);
    for (float i = floor(t)+N; i > floor(t); i--) {
        uv/=zoom_pow;
        vec2 luv = rot(uv + .2*i, i);
        float l = layer(luv, t);
        
        if (i == floor(t)+1.)
            l *= 1. - fract(t);
        
        if (i == floor(t)+N)
            l *= fract(t);
        col = mix(col*fade, vec4(sin(i*5.3)/2. + 0.5,sin(i*8.3)/2. + 0.5,sin(i*2.3)/2. + 0.5,1.), l);
    }
    
    col *= mix(fade, 1., fract(t))/fade;

    // Output to screen
    glFragColor = col;
}
