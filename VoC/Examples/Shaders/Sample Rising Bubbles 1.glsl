#version 420

// original https://www.shadertoy.com/view/WllGRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SIZE 20.
#define BLACK_COL vec3(32,43,51)/255.
#define WHITE_COL vec3(235,241,245)/255.

// Get random value
float rand(vec2 co) { 
    return fract(sin(dot(co.xy , vec2(12.9898, 78.233))) * 43758.5453);
} 

void main(void)
{       
    vec2 uv = gl_FragCoord.xy/resolution.y;
    float smf = 1./(resolution.y) * SIZE * 2.; // smooth factor
    
    vec2 ruv = uv*SIZE;    
    vec2 id = ceil(ruv);       
        
    ruv.y -= time*2. * (rand(vec2(id.x))*0.5+.5); // move up
    ruv.y += ceil(mod(id.x, 2.))*0.3 * time; // every 2nd column always move faster 
    vec2 guv = fract(ruv) - 0.5; // ceneterize guv   
    
    ruv = ceil(ruv);    
    float g = length(guv);
    
    float v = rand(ruv)*0.5; // random bubble size     
    v *= step(0.1, v); // remove too small bubbles
    float m = smoothstep(v,v-smf, g);
    v*=.8; // bubble inner empty space
    m -= smoothstep(v,v-smf, g);
    
    vec3 col = mix(BLACK_COL, WHITE_COL, m); // final color
    
    glFragColor = vec4(col,1.0);
}
