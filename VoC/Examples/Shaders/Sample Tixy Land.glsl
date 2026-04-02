#version 420

// original https://www.shadertoy.com/view/3dtBDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Recreated @aemkey's "Tixy Land" in ShaderToy using shader syntax.
//Play around with the original here: https://tixy.land

#define tixy(t,i,x,y) cos((x*x-x*4.-y*8.+y*y)*.1+8.-t)

/*
    While some codes (like this one) will work on tixy.land too,
    there are plenty of syntax and function name differences.
    You can't use floats and ints interchangably for example.
    Still thought it was fun to try though!
*/

//You can fiddle with dot count here:
#define count 16.

//Render with the result:
void main(void)
{
    float s = 1.2/resolution.y;
    vec2 u = (gl_FragCoord.xy-.5*resolution.xy)*s;
    u.y = -u.y;
    
    float square = step(abs(u.x),.5)*step(abs(u.y),.5);
    vec2 cell = floor((u+.5)*count);
    float index = cell.x+cell.y*count;
    float tixel = float(tixy(time,index,cell.x,cell.y));
    
    float dist = length(fract(u*count)-.5)*count/.5;
    float radius = count*min(abs(tixel),1.);
    
    vec3 col = tixel<0. ? vec3(255,34,68)/255. : vec3(1);
    col *= clamp((radius-dist)/s/count/count/2.,0.,1.)*square;

    glFragColor = vec4(col,1);
}
