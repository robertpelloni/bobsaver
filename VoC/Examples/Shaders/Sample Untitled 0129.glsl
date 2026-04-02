#version 420

//by Gabriel Beaudin bytewav@gmail.com

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void)
{
    vec2 surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 uv = surfacePos;
    uv -= vec2(0.5,1.0);
    uv += sin(uv.x * 12. * (uv.y)  + time) * 0.2;
    float m = clamp((1.3 - abs( uv.y )) * 3.,0.1,1.0);    
    vec3 V = hsv2rgb( vec3((uv.x * 0.2) + time * 0.1 ,1.,1.));
    V *=  m;    
    V *= 1.0 - (sin( uv.y * uv.y * 20.0 ) * 0.1);
    glFragColor = vec4(V,1.0);
}
