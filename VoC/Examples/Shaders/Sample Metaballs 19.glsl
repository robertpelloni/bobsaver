#version 420

// original https://www.shadertoy.com/view/tlyXzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float Count = 12.;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;
    
    //float noise = texture(iChannel0,uv).r;
    //float npnoise = (noise-0.5) *2.0;
    
    
    float MBradius = 0.015;
    vec3 finalcolor;
    
    vec2 metaBalls[int(Count)];
    
    for(float i = .0; i < Count; i++){
        float noise = 0.0;//texture(iChannel0,vec2(i*0.2*cos((time*0.003)),i*0.1*sin((time*0.004)))).r;
        float npnoise = (noise-0.5) *2.0;
        
        
        vec2 MBs = 0.5*sin( time*(i*0.3)+ vec2(1.0+npnoise,0.5+npnoise) )*i/9.0;
        float MBstoUV = distance(uv.xy,MBs);
        float MBsColor = MBradius/MBstoUV;
        finalcolor += vec3(MBsColor*step(0.0,i)*step(i,10.0),MBsColor*step(5.0,i)*step(i,12.0),0.0);
    
        
    }
    
    
    //float finalcolor = MBColor + MB2Color;
    
    vec3 col = mix(vec3(finalcolor.r,0.2,0.2),finalcolor,smoothstep(0.99,1.0,finalcolor.r));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
