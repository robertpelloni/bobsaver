#version 420

uniform vec2 resolution;
uniform float time;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//percentage
#define quality (100.0)
#define zoom (10.0)

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
    
float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

void main( void ) {
    vec2 a = resolution.xy / min(resolution.x, resolution.y);
    vec2 p = (gl_FragCoord.xy / resolution.xy) * a * zoom;
    
    #define tm (time / 3.0 - (distance(p, a * zoom * 0.5) * 0.05))
    p = (p - zoom * 0.5 * a) * mat2(sin(tm), -cos(tm), cos(tm), sin(tm));

    float t = 0.0;
    for(float i = 0.5; i < 5.0;i+= 0.1) {
       t += noise(p.xy * i - vec2(0, (time + 1000.0) / i)) / i ;
    }
    
    t *= quality / 10.0;
    t = t - fract(t);
    t /= quality / 10.0;

    
    glFragColor = vec4(mix(texture2D(backbuffer, gl_FragCoord.xy / resolution.xy).xyz, vec3(sin(t + 0.314), 0, 0), 0.01), 1.0);

}
