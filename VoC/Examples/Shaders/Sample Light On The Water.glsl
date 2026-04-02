#version 420

// Light_on_the_Water.glsl
//
// Trip Me Baby One More Time
//
// Meditative tweak by psyreco
//
// waves added by I.G.P. 2018-10-12 

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------
mat2 rotate(float a) 
{
    float c = cos(a),
    s = sin(a);
    return mat2(c, -s, s, c);
}
//-----------------
vec3 lightShow (in vec2 uv, inout vec3 color)
{
    vec3 rd = vec3(uv, (sin(time*.02+sin(time*0.06)*2.))*uv.y);
    float s = 0.5, t = .5;
    for (int i = 0; i < 9; i++) 
    {
    //t = sin(t+s);
    rd = abs(abs(abs(rd) / abs(dot(sin(rd)+rd,sin(rd)+rd)))); // kali iteration!! Thanks Kali
    rd -= s * t;
    rd.xy *= rotate(0.1 + time *0.017);
    rd.xz *= rotate(0.2 - time *0.053);
    rd.zy *= rotate(0.3 + time *0.081);
    rd *= 2.8 ;
    s *= 0.6;
    t = -sin(t-s)*1.73;
    float b = 0.005;
    float ax = abs(rd.x);
    float ay = abs(rd.y);
    float az = abs(rd.z);
    color.gb -= .003 / max(abs(rd.x*0.2), abs(rd.y*0.8));
    color.gb +=  length(vec2(ax, ay))*0.08/max(ax*0.2, 6.2*ay);
    color.rb -= .002 / max(abs(rd.y*0.6), abs(rd.z*0.6));
    color.rb +=  length(vec2(ay, az))*0.09/max(ay*0.2, 6.2*az);
    color.rg += .001 / max(abs(rd.x*0.7), abs(rd.z*0.9));
    color.rg +=  length(vec2(ax, az))*0.08/max(ax*0.2, 6.2*az);
    }
    color *= 0.33;  // darker
    return color;
}
//-----------------
void waves (in vec2 uv, inout vec3 color)
{
    float mirrorPos = 0.0;
    if (uv.y < mirrorPos) 
    {
        float distanceFromMirror = mirrorPos - uv.y;
        float sine = sin((log(distanceFromMirror)*20.0) - (time*8.0));
        float dy = 44.0*sine;
        float dx = 22.0;
        dy *= distanceFromMirror;
        vec2 pixelSize = vec2(1,1) / resolution.xy;
        vec2 pixelOff = pixelSize * vec2(dx, dy);
        vec2 tex_uv = uv + pixelOff;
        tex_uv.y = (0.6 /* magic number! */) - tex_uv.y;

    color += lightShow(tex_uv, color);
        
        float shine = (sine + dx*0.05) * 0.05;
    color += vec3(shine, shine, shine);
        color *= 0.4 + vec3(0, 0, 0.4);
    }
}
//-----------------
void main() 
{
    vec2 uv = (2.*gl_FragCoord.xy - resolution) / resolution.y;
    vec3 color = vec3(0);
    uv.y += 0.4;            // mirror height  
    if (uv.y < 0.0)         // horizontal mirroring
    { 
      uv.y *= 4.0;          // view angle
      color = vec3(-0.3, -0.3, 1.);  // darker
    }
    
    lightShow (uv, color);
    waves     (uv, color);
    
    glFragColor = vec4(color, 1.);
}
