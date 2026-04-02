#version 420

// original https://www.shadertoy.com/view/tltBDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p)
{
    //from David Hoskins' "Hash without Sine"
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

vec2 fract1(vec2 a){
    return (abs(fract(a*2.0+10.0*hash21(floor(time/5.0)))-.5));
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;
    float t;
    
    for(int c=0;c<3;c++){
        vec2 uv = (gl_FragCoord.xy*5.0-resolution.xy)/resolution.y/10.0;
        uv += vec2(time/2.0,time/3.0)/8.0;
        t = time+float(c)/10.;
        float scale = 4.0;
        float scale1 = 1.7;
        //uv = fract(uv/scale);
        
        for(int i=0;i<9;i++)
        {
            uv = fract1(uv/scale1)+fract1(uv/scale/2.0);
            //scale *= 1.0+fract((uv.x+uv.y)/50.0)/1000.0;
            uv=fract(-uv/(2.5+(-fract(uv.x+uv.y)))+(uv.yx/(2.0))/scale)*scale/1.5+scale1*scale;
            uv /= scale1;

            uv=uv.yx+col.xy;
            //col = fract(col.yzx);
        }
     col[c] = fract((uv.x)-(uv.y));
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}
