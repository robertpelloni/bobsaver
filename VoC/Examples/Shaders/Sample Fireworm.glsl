#version 420

// original https://www.shadertoy.com/view/wsjBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: Reva 2020-05-23
// Title: Fireworm

float rand( vec2 c )
{
    return fract( sin( dot( c.xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453 );
}

vec2 rand2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( rand2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( rand2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( rand2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( rand2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

float circle(vec2 pos, float radius, float glow){
    float sdf = length(pos);
    sdf = smoothstep(radius-0.700,radius,sdf);
    float circles = 1.0 - smoothstep(0.0,1.0,sdf*10.280);
    float glows = exp(-sdf*4.496) * glow * (1.0 - circles);
    return circles+glows;
}

void main(void) {
    vec2 st = (gl_FragCoord.xy - 0.5*resolution.xy )/resolution.y;
    st *= 20.0;
    vec2 uv = st;
    float noisest = noise(vec2(uv.x - time,uv.y - time));
    uv += noisest*0.13;
    uv += vec2( noise(vec2(time)*0.2)*6.0,-time*2.0);
    
    vec3 color = vec3(0.);
    
    
    vec2 pos = fract(uv)-0.5;
    vec2 id = floor(uv);

    
    for(int y = -1; y <= 1; y++){
        for(int x = -1; x <= 1; x++){
            vec2 neighbour = vec2(x,y);
            vec2 rand2 = rand2(id+neighbour);
            float a = noise(rand2+time*2.8);
            vec2 offset = 0.5*(sin(time + rand2*6.28))*2.2;
            float size = rand(id+neighbour)*0.75 + a*0.15;
            color += circle(pos-neighbour+offset,size,size*1.400)/9.0 * vec3(rand2.x*7.884,7.2,rand2.y*6.832);
        }
    }
    
    float xRange = 1.0 - abs(2.0 * st.x)*0.02;
    vec3 ambient = smoothstep(1.0,0.0,st.y*0.05+0.9) * vec3(0.401,0.570,0.443);
    color = max(ambient, color) * xRange;

    glFragColor = vec4(color,1.0);
}
