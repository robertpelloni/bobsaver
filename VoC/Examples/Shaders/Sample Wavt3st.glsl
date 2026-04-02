#version 420

// original https://www.shadertoy.com/view/cdGSzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = resolution.xy, u = (gl_FragCoord.xy+gl_FragCoord.xy-uv)/ uv.y;    
    //glFragColor.rgb*=0.;
    vec2 uv = 10.0 * gl_FragCoord.xy/resolution.xy;
    vec2 translate = vec2(-0.500,-0.500);
    uv += translate;
    
   
    // Time varying pixel color
   
    vec3 col = vec3(0.080,0.440,0.890);
    vec3 col2 = vec3(0.078,0.318,0.882);
    for(int n = 1; n < 50 ; n++){
        float i = float (n);
         uv += vec2(1.0 / i * sin(i * uv.y + time + 10.0 * i) + 0.8, 
         0.4 / i * sin(uv.x + time + 0.3 * i)+2.0);
        
        
    }
    col += 1.128 * sin(uv.y) + -0.500, 0.5 * cos(uv.x) + 0.5, sin(uv.x + uv.y);
    col2 += sin(uv.x *cos(time/2.0) * 0.1 + sin(uv.y * sin(time / 60.0) * 100.0));
    col += sin(uv.x *sin(time/1200.0) * 50.0 + sin(uv.x * sin(abs(time / 60.0)) * 20.0));
    // Output to screen
    glFragColor = vec4(col,1.0);
}
