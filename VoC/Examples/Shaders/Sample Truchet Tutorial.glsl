#version 420

// original https://www.shadertoy.com/view/Wdc3Df

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec2 uv)
{
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);    
}

void main(void)
{
    vec2 uv = ((gl_FragCoord.xy/resolution.y)-(resolution.xy/resolution.y*.5))*2.;
    uv *= sin(time*2.)*10. + 12.;
    float angle = time * .5;
    float c = cos(angle);
    float s = sin(angle);
    uv *= mat2( c, -s, s, c);
    uv += vec2(time)*6.;
   
    vec2 gv = (fract(uv)-.5)*2.;
    vec2 id = vec2(int(uv.x), int(uv.y));
   
    vec3 col = vec3(0);
    if( random(id) < 0.5 )
    {
         gv.x *= -1.;
    }

    if(distance(vec2(1), gv) < 1.1 && distance(vec2(1), gv) > 0.9 ||
       distance(vec2(-1), gv) < 1.1 && distance(vec2(-1), gv) > 0.9)
      {
        col = vec3(1);
       }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
