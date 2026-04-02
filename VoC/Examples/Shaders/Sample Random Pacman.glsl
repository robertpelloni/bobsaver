#version 420

// original https://www.shadertoy.com/view/slsczf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdPie( in vec2 p, in vec2 c, in float r )
{
    p.x = abs(p.x);
    float l = length(p) - r;
    float m = length(p-c*clamp(dot(p,c),0.0,r)); // c=sin/cos of aperture
    return max(l,m*sign(c.y*p.x-c.x*p.y));
}

float Hash21(vec2 p){
    p = fract(p*vec2(123.45, 234.56));
    p+=dot(p,p+23.4);
    return fract(p.x*p.y);
}

float starDust(vec2 p, float scale, float deg){
    p*=scale;

    vec2 id = floor(p);
    p = fract(p)-0.5;
    float n = Hash21(id);
    
    vec2 size = vec2(0.1,0.1);
    p*=Rot(radians(deg));
    float r = 0.4*n+0.1;
    float d = sdPie(p,vec2(0.05-abs(sin(time*5.0)*0.045),-0.02),0.4*n+0.1);
    float eye = length(p-vec2(r*0.4,0.0))-r*0.1;
    d = max(-eye,d);
    d = S(d,0.0);
    
    d*=pow(abs(sin(n*20.0+time*0.5)),30.0);
    return d;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 prevP = p;
    vec3 col = vec3(0.0);

    p.x+=time*0.2;
    col+=starDust(p,5.0,90.0);
    p = prevP;
    p.x-=time*0.2;
    col+=starDust(p,6.0,-90.0);
    
    p = prevP;
    p.y+=time*0.2;
    col+=starDust(p,7.0,0.0);
    p = prevP;
    p.y-=time*0.2;
    col+=starDust(p,8.0,-180.0);
    
    glFragColor = vec4(col*vec3(1,1,0),1.0);
}
