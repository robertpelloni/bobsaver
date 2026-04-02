#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ws3fWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4  fC () {
    vec3 col;
    float t = time*.05;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y+vec2(t+2.0);
        //uv *= 10.0;
        int c = 0;
        for(int i=0;i<9;i++)
        {
            c = i%3;
            float factor = 1.5;
            vec2 uv1 = uv;
            uv /= factor;
            uv += uv1;
            uv += (sin(uv.yx+time/5.))/factor;
            uv *= factor;
            col[c] += sin(uv.x+uv.y);
            col=col*vec3(.45,.2,.9);
        }
    return  vec4(col*10.0,1.0);
}

// Add this code to the bottom of any shader that has aliasing:
void main(void)
{
    glFragColor = vec4(0);
    float A = 1.,  // Change A to define the level of anti-aliasing (1 to 16) ... higher numbers are REALLY slow!
          s = 1./A, x, y;
    
    for (x=-.5; x<.5; x+=s) for (y=-.5; y<.5; y+=s) glFragColor += min ( fC(), 1.0);
        
    glFragColor /= A*A;
}
