#version 420

// original https://www.shadertoy.com/view/ldsfDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define C(uv) \
(1.-(step(distance(uv, vec2(0.15,0.15) ), .1+.0125*abs(sin(t*.25)) )\
+step(.07, distance(uv-vec2(.06,.06), vec2(0.))))\
-step(distance(vec2(uv.x,uv.y)+vec2(.06,.06), vec2(0.05)),.07)\
)

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5;
    float    t = time;
    float    a = .008+t*.06125;;
    mat2    rot = mat2(cos(a),sin(a),-sin(a),cos(a));

    uv *=.25;
    uv *= mat2(cos(t), sin(t), -sin(t), cos(t));
    vec4 o = vec4(0.,0.,0.,1.0);
    float s = 0.;
    for (int i = 0; i < 30; i++)
    {
        uv *= 1.1;
        uv *= rot;
        o.x = max(C(uv),o.x);
        if(o.x > 0.)
            break;
        s++;
    }
    o.x -= .5*o.x*abs(sin(280.*(uv.x)-t*2.))-.25*o.x*abs(sin(1000.*(uv.x)+t*4.))
        +.125*o.x*abs(sin(300.*(uv.x)+t*1.));
    o.x -= .5*o.x*abs(sin(280.*(uv.y)-t*2.))-.25*o.x*abs(sin(1000.*(uv.y)+t*4.))
        +.125*o.x*abs(sin(300.*(uv.y)+t*1.));
    o.xyz = o.x*vec3(
                      abs(sin(s*2.+1.*3.14/3.)) ,
                      abs(sin(s*2.+2.*3.14/3.)) ,
                      abs(sin(s*2.+3.*3.14/3.)) 
                      ); 
    glFragColor=o;   
}
