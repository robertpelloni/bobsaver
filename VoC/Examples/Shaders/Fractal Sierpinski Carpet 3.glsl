#version 420

// original https://www.shadertoy.com/view/WdGGWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
const float iter = 6.0;

vec2 tile(vec2 uv) {
    uv *= 3.;
    uv = fract(uv);  
    return uv;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec3 hsv2rgb( vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return mix( vec3(1.0), rgb, c.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.x/resolution.y;
    vec2 tiling = vec2(aspect, 1.);
    uv.x *= aspect;
    uv.x -= (aspect - 1.) / 2.;
    
 
    vec3 color = vec3(0.0);
    vec3 colorr = vec3(0.0);
    vec3 green = vec3(.3, .5, .1);
    
    if(uv.x > 1. || uv.x < .0) {     
        color = vec3(1.0);
        colorr = green;
    }
    else {
        uv = rotate2d(PI / 4.) * uv;
        vec3 hsl = vec3( uv.x / 2. + time * .5, 1.0, uv.y );
        colorr = hsv2rgb(hsl);
        uv = rotate2d(-PI / 4.) * uv;
    
        
        for(float i = 0.; i < iter; ++i) {

            vec3 color1 = vec3(step(1./3., uv.x) - step(2./3., uv.x));
            vec3 color2 = vec3(step(1./3., uv.y) - step(2./3., uv.y));

            color = color1 * color2;

            if(color == vec3(1.))
                break;

            float pas = floor((fract(time*.2) * iter));
            if(i == pas)
                break;

            uv = tile(uv);
        }
    }
    
    color *= colorr;
    glFragColor = vec4(color, 1.0);
    
}
