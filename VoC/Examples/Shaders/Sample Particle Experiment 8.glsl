#version 420

// original https://www.shadertoy.com/view/ltfXDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

void main(void)
{
    float t = time+5.;
        
    // vars
    float z = 2.5;
    
    const int n = 100; // particle count
    
    vec3 startColor = normalize(vec3(1.,0.,0.));
    //vec3 endColor = normalize(vec3(0.2,0.2,.8));
    vec3 endColor = normalize(vec3(1.,sin(t)*.5+.5,cos(t)*.5+.5));
    
    float startRadius = 1.;
    float endRadius = 2.;
    
    float power = 0.8;
    float duration = 4.;
    
    vec2 
        s = resolution.xy,
        v = z*(2.*gl_FragCoord.xy-s)/s.y;
    
    vec3 col = vec3(0.);
    
    vec2 pm = v.yx*2.8;
    
    float dMax = duration;
    
    float mb = 0.;
    float mbRadius = 0.;
    float sum = 0.;
    for(int i=0;i<n;i++)
    {
        float d = fract(t*power+48934.4238*sin(float(i)*692.7398))*duration;
        float a = 6.28*float(i)/float(n);
         
        float x = d*cos(a);
        float y = d*sin(a);
        
        float distRatio = d/dMax;
        
        mbRadius = mix(startRadius, endRadius, distRatio); 
        
        v = mod(v,pm) - 0.5*pm;
        
        vec2 p = v - vec2(x,y);
        
        p = mod(p,pm) - 0.5*pm;
        
        mb = mbRadius/dot(p,p);
        
        sum += mb;
        
        col = mix(col, mix(startColor, endColor, distRatio), mb/sum);
    }
    
    sum /= float(n);
    
    col = normalize(col) * sum;
    
    sum = clamp(sum, 0., .5);
    
    vec3 tex = vec3(1.);
     
    col *= smoothstep(tex, vec3(0.), vec3(sum));
        
    glFragColor = vec4(col,1) * 0.2 + texture2D(backbuffer, gl_FragCoord.xy/s) * 0.8;
}
