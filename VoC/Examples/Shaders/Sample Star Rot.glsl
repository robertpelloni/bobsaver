#version 420

// original https://www.shadertoy.com/view/3s2yzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592

vec2 rotate(float a,vec2 pos){
    float c = cos(a);
    float s = sin(a);
    mat2 rot = mat2(c,-s,s,c);
     return rot*pos;  
}

vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy);
    uv /= resolution.xy;
    uv.x *= resolution.x/resolution.y;
    
    //uv *= 200.*(1.-0.8*abs(sin(time)));
    uv *= 16.;
    
    //uv = rot*uv;
    float fVal = 0.;
    // Time varying pixel color
    float linterp = abs(fract(time/4.)*2.-1.);
    float linterp0 = abs(fract(time/16.)*2.-1.);
    //linterp = step(0.5,linterp0);
    linterp = 1.;
    float linterp1 = abs(fract(time/4.)*2.-1.)*0.1+0.55;
    float linterp2 = abs(fract(time/4.)*2.-1.)*0.1+0.0;
    
    //float rain = step(0.5,linterp);
    float rain = 0.;
    //int iter = int(abs(fract(time/2.)*2.-1.)*8.+1.9);
    //int iter = int(abs(sin(time*1.)*8.)+2.);
    int iter = 8;
    
    vec3 sc;
    vec3 fc = vec3(0.);
    for(int i = 0; i <iter; i++){
    float it = float(i);
    float n = float(iter);
    uv = rotate(PI/(2.*float(iter)),uv);
    //vec2 p = rotate(time*5.,uv);
    vec2 p = uv;
      //uv = rot* uv;
    float xval = 1./abs(p.x);
    p.y *= 1.;
    float val = 1.-smoothstep(xval,xval+abs(p.y),abs(p.y));
    float r = 255.*(it/(n-1.));
    float b = 255.*((n-1.-it)/(n-1.));
    //r = 255.;
    //vec3 color = vec3(b,0.,r)/255.;
    vec3 color = hsl2rgb(vec3(linterp1*(linterp) + (1.-linterp)*linterp2,0.5,abs(sin((it/(n-1.))+time*2.))));
    
        
        
    sc = vec3(val)*color;    
        
    float pbright = 1.-step(0.1,(fc.x+fc.y+fc.z)/3.); 
    float cbright = smoothstep(0.9,1.,val);
    //fc = cbright*sc + (1.-cbright)*fc; 
    fc = mix(fc,sc,cbright);
        
    //fc = mix(sc,fc,0.55);    
    
    //fc += sc;    
        
    //fVal = max(val,fVal);  
    
    }
    //float val = smoothstep(xval,xval+0.1,abs(uv.y));
    //float val = step(xval,uv.y);
    //vec3 col = vec3(fVal);
    vec3 col = fc;
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
