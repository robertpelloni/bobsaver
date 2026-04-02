#version 420

// original https://www.shadertoy.com/view/ttSGzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define scale 5.

mat2 rot(float a)
{
 return mat2(cos(a), -sin(a), sin(a), cos(a));   
}

float rnd(vec2 p)
{
 return fract(sin(dot(p, vec2(12.9898, 78.233)))*43578.23414);   
}

float lines(vec2 p, float th)
{
    float x = fract(p.x*12.+0.35);
    float ss = 0.09;
 float line = smoothstep(th-ss,th+ss, x)*smoothstep(th+0.3+ss,th+0.3-ss, x);
    
    
 return line*step(p.y, pow(floor(p.x*12.)/12.+0.05, 8.)/1.);   
}

float vig (vec2 st)
{
    st *=  1.0 - st.yx;
    float vig = st.x*st.y*15.;
    vig = pow(vig, 0.1); 
    return vig;
}

vec2 quadRot(vec2 p)
{
    float index = 0.0;
    p = p*scale;
    //square waves
    index = floor(mod(p.x, 2.));
    index += floor(mod(p.y, 2.))*2.;
    p = fract(p)-0.5;
    //rot quads
    
    if(index == .0)
    {
        p = p*rot(-3.14/2.);
    }
    else if(index == 1.0)
    {
      p = p*rot(3.14*2.);  
    }
    else if(index == 2.0)
    {
     p = p*rot(-3.14);   
    }
    else if(index == 3.0)
    {
      p = p*rot(-3.14/2.);  
    }
    
   
    
 return p+0.5;   
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
     uv.x*=resolution.x/resolution.y;
    uv+=time/8.;
    
    vec2 index = floor(uv*scale);
    float tex0 = 0.0;//vec3(texture(iChannel0, uv/3.)).x;
    
    //quad rot has to happen before the fract..
    uv = quadRot(uv);
   
   // uv=fract(uv*4.);//textures
    
    float tex1 = -(abs(sin(uv.x*scale+time*1.+uv.y*scale)/1.)-0.25);//gold movement
    float tex2 = 0.0;//vec3(texture(iChannel2, uv)).x;
    
    
    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    col = vec3(0.4,0., 0.0)*tex0/10.+ rnd(index)/2.;
    col = mix(col, vec3(0.5,0., 0.0)-(rnd(index)-0.95)/.5, step(0.4, rnd(index)/2.));
    col = mix(col, vec3(188., 139., 20.)/255.+tex1/1., lines(uv, 0.5));
    
    
    // Output to screen
    glFragColor = vec4(col*vig(uv),1.0);
}
