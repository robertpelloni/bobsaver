#version 420

// original https://www.shadertoy.com/view/stSXDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = acos(-1.);

//https://gist.github.com/companje/29408948f1e8be54dd5733a74ca49bb9
float map_range(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

//https://gist.github.com/ayamflow/c06bc0c8a64f985dd431bd0ac5b557cd
vec2 rotateUV(vec2 uv, float rotation)
{
    float mid = 0.5;
    return vec2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

float map(vec2 uv) {
    int iterations = 15;
    vec2 ouv = uv;
    
    uv.y += time/16.;
    uv = abs(mod(uv, 1.)*4. - 2.);
    
    for(int i = 0; i < iterations; i ++) {
        float fi = float(i);
        float fit = float(iterations);
        
        uv = abs(uv - (vec2(0.5 + (fi/fit)*0.6 )));
        
        uv *= 1.16;
        
        uv = rotateUV(uv, map_range(ouv.x,-1.,1., 0.2, 5.) );
    }
    
    return sin(length(uv)*10.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 uv_o = uv;
    
    //Log polar-tiling -> https://www.osar.fr/notes/logspherical/
    vec2 pos = vec2(log(length(uv)), atan(uv.y, uv.x));
    pos *= 1./pi;
    pos = fract(pos) - 0.5;   
    uv = pos;
    uv.x -= time/5. + 5700.;
    
    //RGB offset
    float offset_range = 0.005;
    float offset = map_range(sin(time),-1.,1.,0.2,1.) * offset_range;
    float offset_y = cos(time) * offset_range * 0.2;
    
    float cr = map(uv + vec2(offset, 0.));
    float cg = map(uv + vec2(offset*2., offset_y*2.));
    float cb = map(uv + vec2(offset*3., offset_y*3.));
    vec3 color = vec3(cr, cg, cb)*3.;
    
    //Fade to black towards center to hide aliasing
    float mask = (1. - pow(length(uv_o),0.96) )*3.;
    color -= mask;
    
    glFragColor = vec4(color,1.0);
}
