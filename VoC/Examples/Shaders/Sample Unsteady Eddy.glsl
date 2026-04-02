#version 420

// original https://www.shadertoy.com/view/fts3z8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float c (float oldCos) {
    float newCos = 0.5 + 0.5*cos(oldCos*3.14159265359);
    return newCos;
    }

float s (float oldSin) {
    float newSin = 0.5 + 0.5*sin(oldSin*3.14159265359);
    return newSin;
    }

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;  // Normalized pixel coordinates (from 0 to 1)
    uv -= 0.5;                           // remap so 0,0 is in the middle of the screen.
 
    float x = uv.x;
    float y = uv.y;
    float o = time * 0.25;
    float d = length(uv);
    float rad  = (3.14159265359 + atan(uv.y,uv.x)) * 0.15915494309  ;
    //note - is this the best way to calculate normalised (0..1) radial angle??? 
    //Leave a comment if you read this and can improve it!
    

    // Time varying pixel color    
    float r = s(c(d*4. + o*2.)+s((rad+c(o))*10.));
    float g = s(d*6. + s(r*2.+o));
    float b =s(r*8. + s(g*2.));
    
    vec3 col = vec3(r, g, b);
       
    // Output to screen
    glFragColor = vec4(col,1.0);
}
