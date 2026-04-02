#version 420

// original https://www.shadertoy.com/view/wsSyRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec3 col;
    float minSize = 50.;
    float mergez =0.;

    float popx = cos(uv.x*minSize*(0.5+0.5*cos(time))-0.5*cos(time)*minSize*0.5);
    float popy = cos(uv.y*minSize*(0.5+0.5*cos(time))-0.5*cos(time)*minSize*0.5);

    if(popx<mergez ^^ popy<mergez){
        //col = vec3(0,0,0);
        col = vec3(0.5,0.5 + 0.5*cos(uv.xy+time));
    }
    else{
        //col = vec3(1,1,1);
        col = vec3(0.5 + 0.5*cos(uv.xy+time),0.5);
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
