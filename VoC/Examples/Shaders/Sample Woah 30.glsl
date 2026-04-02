#version 420

// original https://www.shadertoy.com/view/WdKczD

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
        vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
        t = time+float(c)/10.;
        for(int i=0;i<10;i++){
            uv=abs(uv);
            uv-=.5;
            uv=uv*rot(t/float(i+1));
        }
        col[c]= step(.5,fract(uv.x*20.));
    }

    glFragColor = vec4(vec3(col),1.0);
}
