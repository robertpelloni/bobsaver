#version 420

// original https://www.shadertoy.com/view/wsycD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){return mat2(cos(a),-sin(a),sin(a),cos(a));}

void main(void)
{

    vec3 col;
    float t;
    
    for(int c=0;c<3;c++){
        vec2 uv = (gl_FragCoord.xy*20.0-resolution.xy)/resolution.y;
        t = time;
        for(int i=0;i<5;i++)
        {
            uv += sin(col.yx);
            uv += float(i) + (sin(time+uv.x)+cos(time+uv.y));
        }
     col[c] = (sin(uv.x)+cos(uv.y));
    }
    
    glFragColor = vec4(col,1.0);
    
}
