#version 420

// original https://www.shadertoy.com/view/wsByRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BLUR 0.005
#define LAYER 3.

float window(vec2 uv, float w, float h, float circular){
    float f = 1.0 - smoothstep(circular-BLUR,circular, 1.0 - uv.x * uv.y);
    f *= 1.0 - smoothstep(circular-BLUR,circular, 1.0 - (w - uv.x) * uv.y);
    f *= 1.0 - smoothstep(circular-BLUR,circular, 1.0 - (w - uv.x) * (h - uv.y));
    f *= 1.0 - smoothstep(circular-BLUR,circular, 1.0 - uv.x * (h - uv.y));
    return f;
}

float hash21(vec2 p)
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*(p.x+p.y) );
}

vec3 windowLayer(vec2 uv){
    vec3 col = vec3(0.0);
    
    vec2 pos = fract(uv);
    vec2 id = floor(uv);
    
    for(int y = -1; y < 1; y++){
        for(int x = -1; x < 1; x++){
          vec2 offset = vec2(x,y);
          float random = hash21(id+offset);
          vec3 c = vec3(random*0.3+0.1, fract(random*49.43)*0.6+0.4, 0.8)*(sin(time*random*6.28)*0.4+0.6);
          vec2 size = vec2(random*0.5+0.8,fract(random*984.33)*0.5+0.8);
          col += window(pos - offset-vec2(random,fract(random*39.53))*0.5,size.x,size.y,0.999)*c;
        }
    }
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0.0);
    for(float i = 0.; i < 1.; i+= 1./LAYER){
        float depth = fract(i+time*0.1);
        float scale = mix(20.,0.5,depth);
        float fade = depth*smoothstep(1.,0.9,depth);
        col += windowLayer(uv*scale+i*93.4+5.7)*fade;
    }
    
    glFragColor = vec4(col,1.0);
}
