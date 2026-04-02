#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(int seed, float ray) {
    return mod(sin(float(seed)*363.5346+ray*674.2454)*6743.4365, 1.0);
}

vec4 ligth(vec2 position, vec3 color) {
    float pi = 3.14159265359;
    float ang = atan(position.y, position.x);
    float dist = length(position);
    vec4 ret;
    ret.rgb = vec3(color.r * 0.8, color.g * 0.6, color.b * 0.9) * (pow(dist, -1.0) * 0.05);
    for (float ray = 0.0; ray < 8.0; ray += 1.0) {
        //float rayang = rand(5234, ray)*6.2+time*5.0*(rand(2534, ray)-rand(3545, ray));
        float rayang = rand(5234, ray)*6.2+(mouse.x+time*0.01)*10.0*(rand(2546, ray)-rand(5785, ray))-mouse.y*10.0*(rand(3545, ray)-rand(5467, ray));
        rayang = mod(rayang, pi*2.0);
        if (rayang < ang - pi) {rayang += pi*2.0;}
        if (rayang > ang + pi) {rayang -= pi*2.0;}
        float brite = .3 - abs(ang - rayang);
        brite -= dist * 0.2;
        if (brite > 0.0) {
            ret.rgb += vec3(color.r+0.4*rand(8644, ray), color.g+0.4*rand(4567, ray), color.b+0.4*rand(7354, ray)) * brite;
        }
    }
    ret *= smoothstep(0.5, 0.0, distance(position, mouse/resolution.x));
    return ret;
}

void main( void ) { 
    
    vec2 position = ( gl_FragCoord.xy / resolution.xy ) - mouse;
    position.y *= resolution.y/resolution.x;

    glFragColor = 
          ligth(position, vec3(1.0, 1.0, 1.0)) 
        + ligth(position + vec2(0.2, 0.2), vec3(1.0, 0.0, 0.0)) 
        + ligth(position + vec2(-0.2, 0.2), vec3(0.0, 1.0, 0.0)) 
        + ligth(position + vec2(0.2, -0.2), vec3(0.0, 0.0, 1.0)) 
        + ligth(position + vec2(-0.2, -0.2), vec3(1.0, 1.0, 0.0));
}
