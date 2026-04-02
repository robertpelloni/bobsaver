#version 420

// original https://www.shadertoy.com/view/3t2yRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    uv.y += .5*sin(time)-.2,.5;
    float a = cos(time)*.6;
    uv = uv*mat2(cos(a),-sin(a),sin(a),cos(a));
    
    
    const float h = -.1; // horizon
    const float sc = 8.; // scale
    const float sp = 10.; // speed
    
    float f = distance(uv,vec2(a,-0.08));
    float e = smoothstep(f,f+1.,.9)*step(h,uv.y);
    e += smoothstep(f,f+.01,.2);

    float d = 1./abs(uv.y*2.); //depth
    vec2 pv = vec2(uv.x*d, d); //perspective
    pv.x += a;
    pv.y += time*1./sc*sp; //offset
    pv *= sc; 
    pv = abs((fract(pv)-.5)*2.); //grid vector
    
    
    float c = smoothstep(length(pv),length(pv)+1./sc,.6)*smoothstep(uv.y,uv.y+1.2/sc,h);
    
    c *= abs(uv.y*2.);
    vec3 col = vec3(c,0.,0.1);
    
    col = mix(col,vec3(e,e/2.,1.-e)*step(h,uv.y),.5);

    glFragColor = vec4(pow(col,vec3(1./2.2))*1.5,1.);
}
