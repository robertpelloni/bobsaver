#version 420

// original https://www.shadertoy.com/view/lt2XWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Ethan Alexander Shulman 2016

float len(vec3 p) {
    return max(abs(p.x)*0.5+abs(p.z)*0.5,max(abs(p.y)*0.5+abs(p.x)*0.5,abs(p.z)*0.5+abs(p.y)*0.5));
}

void main(void)
{
    vec2 R = resolution.xy,
        uv = (gl_FragCoord.xy - .5*R) / resolution.y;
    
    vec3 rp = vec3(0.,resolution.y/50.,time+resolution.x/50.);
    vec3 rd = normalize(vec3(uv,1.));
    
    vec3 c = vec3(0.);
    float s = 0.;
    
    float viewVary = cos(time*0.05)*.15;
    
    for (int i = 0; i < 74; i++) {
        vec3 hp = rp+rd*s;
        float d = len(cos(hp*.6+
                             cos(hp*.3+time*.5)))-.75;
        float cc = min(1.,pow(max(0., 1.-abs(d)*10.25),1.))/(float(i)*1.+10.);//clamp(1.-(d*.5+(d*5.)/s),-1.,1.);
        
        c += (cos(vec3(hp.xy,s))*.5+.5 + cos(vec3(s+time,hp.yx)*.1)*.5+.5 + 1.)/3.
              *cc;
        
        s += max(abs(d),0.35+viewVary);
        rd = normalize(rd+vec3(sin(s*0.5),cos(s*0.5),0.)*d*0.05*clamp(s-1.,0.,1.));
    }
    
    glFragColor = vec4(pow(c,vec3(1.7)),1.);
}
