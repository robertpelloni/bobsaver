#version 420

// original https://www.shadertoy.com/view/fsBGDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define hue(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
#define rot(a)mat2(cos(a),sin(a),-sin(a),cos(a))

void main(void)
{
    vec4 O=vec4(0);
    vec3 p,r=vec3(resolution.xy,1.0),
    d=normalize(vec3((gl_FragCoord.xy-.5*r.xy)/r.y,1));  
    for(float i=0.,j,g,e;i++<99.;){
        vec3 p=d*g;
        p.z-=-1.;
        p.y-=p.z*.6;
        p.xz*=rot(time*.1);
        // https://www.shadertoy.com/view/MlfXW7
        vec2 z=p.xz;
        for(j=5.;dot(z,z)<4.&&j++<99.;)
            z=mat2(z,-z.y,z.x)*z+vec2(.3,.48)*rot(sin(time)*.1);       
        e=p.y+log2(log(j))*exp(-.002*j*j)*.1;
        g+=e*.5;
        O.rgb+=hue(log(j))*log(1./abs(e))/1000.;
    }
    glFragColor=O;
}
