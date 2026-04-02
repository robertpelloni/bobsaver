#version 420

// original https://www.shadertoy.com/view/td33Rr

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define resolution resolution
#define frame frames
#define pixel_width 1./resolution.y

const float speed = .5;
const float grid = 10.;
const float size = 1.5;
const float falloff = 64.;
float t;

float random (vec2 st) {
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}

vec2 GetPos(vec2 id, vec2 offs, float t) {
    float n = random(id+offs);
    float n1 = fract(n*10.);
    float n2 = fract(n*100.);
    float a = t+n;
    return offs + vec2(sin(a*n1), cos(a*n2))*.5;
}

void main(void)
{
    t = time*speed+10.;
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    uv = uv * grid;

    
    float minDist = 100.;
    float expDist = 0.;
    vec2 minId;
    for (int i =-1; i<=1; i++) {
        for (int j =-1; j<=1; j++) {
            vec2 offset = vec2(i,j);
            vec2 id = floor(uv);
            vec2 gv = fract(uv) - 0.5;
            vec2 pos = GetPos(id, offset, t);
            float p_size = random(id+offset)/20.*size;
            float dist = length(gv-GetPos(id, offset, t));
            expDist += exp( -falloff*dist );
            if (dist<minDist) {
                minDist = dist;
                minId = id+offset;
            }
        }
    }
    expDist = -(1.0/falloff)*log(expDist);

    float col = minDist; //smoothstep(pixel_width*grid,0.0,0.90-expDist);
    // Output to screen
    glFragColor = vec4(vec3(col),1.0);
}
