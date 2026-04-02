#version 420

// original https://www.shadertoy.com/view/MlSczR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(float n) {
     return fract(cos(n*89.42)*343.42);
}

vec2 hash2(vec2 n) {
     return vec2(hash(n.x*23.62-300.0+n.y*34.35),hash(n.x*45.13+256.0+n.y*38.89)); 
}

float worley(vec2 c, float time) {
    float dis = 1.0;
    for(int x = -1; x <= 1; x++)
        for(int y = -1; y <= 1; y++){
            vec2 p = floor(c)+vec2(x,y);
            vec2 a = hash2(p) * time;
            vec2 rnd = 0.5+sin(a)*0.5;
            float d = length(rnd+vec2(x,y)-fract(c));
            dis = min(dis, d);
        }
    return dis;
}

float worley5(vec2 c, float time) {
    float w = 0.0;
    float a = 0.5;
    for (int i = 0; i<5; i++) {
        w += worley(c, time)*a;
        c*=2.0;
        time*=2.0;
        a*=0.5;
    }
    return w;
}

void main(void)
{
    float dis = worley5(gl_FragCoord.xy/64.0, time);
    vec3 c = mix(vec3(1.0,0.95,0.5), vec3(0.7,0.0,0.0), dis);
    glFragColor = vec4(c*c, 1.0);
}
