#version 420

// original https://www.shadertoy.com/view/3dKGR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//plento

vec2 R;
const float pi = 3.1415926;
float hsh(vec2 p)//Dave hoshkin hash ya
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);}
void main(void)
{
    vec4 f = glFragColor;
    vec2 u = gl_FragCoord.xy;

    R = resolution.xy;
    vec2 uv = vec2(u.xy - .5*R.xy)/R.y;
    vec3 col = vec3(1);
    
    float d = .75; // speed factor
    
    
    float m = exp(abs(sin(uv.x*2. -time*d)));
    
    //m = min(m,2.0); // makes flat planes
   // m = max(m,1.5);
    
    uv.y*=m; // remmapping y coords to the function
    
    uv.y+=time*.7;
    uv.x-=time*(d/2.);
    col*=(step(0., sin(-uv.x*2.)) + .3); // dark shadow every other crest
    uv.x*=(3./pi)*4.; 
    
    // id and repeated coord
    vec2 fuv = fract(uv*6.);
    vec2 id = floor(uv*6.);
    
    //checkerboard value
    float chk = mod(id.y+id.x,2.);
   
    // shading/color
    col*=mix(vec3(1., 0., .5), vec3(0.,.6, .2), hsh(id));
    col *= smoothstep(.7, .27,abs(fuv.y-.5))*chk;
    col *= smoothstep(3.4, .9, m);
    
    f = vec4(col, 1.);

    glFragColor = f;
    
}
