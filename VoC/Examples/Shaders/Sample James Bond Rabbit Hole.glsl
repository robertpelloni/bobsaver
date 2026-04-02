#version 420

// original https://www.shadertoy.com/view/tlG3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5 * resolution.xy)/resolution.y;
     float t = time * .2;
    //uv *= mat2(cos(t),-sin(t),sin(t),cos(t));
    vec3 ro = vec3(0, 0, -1);
    vec3 lookat  = mix(vec3(0),vec3(-1,0,-1),sin(t*1.56)*.5+.5);
    float zoom = mix(.2,.7,sin(t)*.5+.5);
    
    vec3 f = normalize(lookat-ro),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = ro + f * zoom,
        i = c + uv.x * r + uv.y * u,
        rd = normalize(i-ro);
                      
    float radius = .7;
    float d5, dO;
    vec3 p;
                      
     for(int i = 0; i<100; i++) {
         p = ro + rd * dO;
         d5 = -(length(vec2(length(p.xz)-1.,p.y)) - radius);
         if (d5<.001) break;
         dO += d5;
     }
   
    vec3 col = vec3(0);

    if(d5<.001) {
       float x = atan(p.x,p.z)+t*mix(.4,.8,sin(t)*.01+.5);
       float y = atan(length(p.xz)-1.,p.y);
      
        float bands = sin(y*10.+x*20.);
        float ripples = sin((x*10.-y*30.)*3.)*.5+.5;
        float waves = sin(x*2.-y*6.+t*10.);
        
       float b1 = smoothstep(-.2,.2, bands);
       float b2 = smoothstep(-.2,.2, bands-.5);
        
        float m = b1*(1.-b2);
        m = max(m, ripples*b2*b2*max(0.,waves));
        m += max(0.,waves*.3*b2);
        
        col+= mix(m, 1.-m,smoothstep(-.3,.3, sin(x*2.+t)));//+texture(iChannel1, uv*.9+time*+.001).rgb;
   
     col.rg += uv.xy;}
    glFragColor = vec4(col,.2);
     col.rg = uv;
}
