#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

mat2 rotate(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

void main() {
    
    vec2 uv = 1.3 * (2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec2 u = gl_FragCoord.xy / resolution;
        
    float scl = 50. + 50. * abs(sin(time));
    uv = floor(uv * scl) / scl;
    vec3 col = vec3(0.);
    
    float r = .1;
    for (float i = 0.; i < 15.; i++) {
        
        
        float a = atan(uv.x, uv.y) + time * i / 10.;
        float n = 6.28 / 20.;
        a = mod(a, n) - n / 2.;
        float l = length(uv);
        
        vec2 p = l * vec2(cos(a), sin(a));
            
        p.x -= .4 + i * .05;
        float d = length(p);
        
        r *= .8;
        col += .001 / d;
        col += smoothstep(r + .025, r, d);
        col *= .5 + .5 * cos(time + d /  2. + vec3(23, 21, 0));
    
        
    }
    
    
    u -= .5;
    u *= (2. + .2 * sin(time));
    col += texture2D(backbuffer, u + .5).rgb * 0.9;
    
    
    
    glFragColor = vec4(col, 1.);

}
