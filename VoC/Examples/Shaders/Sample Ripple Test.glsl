#version 420

// original https://www.shadertoy.com/view/td23zd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    //glFragColor = vec4(col,1.0);
    
    
    //vec3 color = vec3(0.0);
    //uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
      //uv.x *= resolution.x/resolution.y;
    //float d = length(uv) - 0.3;
    //d = 0.005/pow(d, 2.0);
    //float col2 = rand(uv);
    //color = d * vec3(abs(sin(time)), abs(cos(time)), col2);
    //glFragColor = vec4(color, 1.0);
    
    vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    float uvLength = length(uv);

    vec2 newuv = gl_FragCoord.xy/resolution.xy+(uv/uvLength)*sin(uvLength*10.0-time*5.0)*0.5;

    glFragColor = vec4(newuv.x*0.1,newuv.y*0.4, 0.9,1.0);

}
