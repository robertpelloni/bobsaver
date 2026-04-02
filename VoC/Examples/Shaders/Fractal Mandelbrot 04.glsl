#version 420

// original https://www.shadertoy.com/view/tdjBDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),sin(_angle),cos(_angle));
}

#define MAXITER 810
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv = uv*2.5-vec2(.5,0.);
    float t = time * .15;
    float angle = t;    
    uv *= rotate2d(angle);
    float scale = 1.5;
    uv *= 1.-sin(scale);
    uv.x -= scale * (sin(scale)/2.+.03);
    uv.y -= scale * (sin(scale)/5.-.30);
    vec2 c = uv;
    vec2 z = c;
    int escape = 0;
    for(int i = 0;i<MAXITER;i++){
        float tempx = z.x*z.x - z.y * z.y + c.x;
        z.y = 2. * z.x * z.y + c.y;
        z.x = tempx;
        if(length(z)>2.){
           escape = i;
            break;
        }
    }
    
    float sl = (float(escape) + log2(length(z)))/float(MAXITER);
    vec3 col = vec3(sin(sl)*2.*cos(time), sin(sl)/3.,cos(sl)/4.);
    col += sl;
    if(length(z)<2.0){
      col = vec3(1.);   
    }
    glFragColor = vec4(col,1.0);
}
