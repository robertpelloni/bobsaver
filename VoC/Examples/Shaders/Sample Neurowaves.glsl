#version 420

// original https://www.shadertoy.com/view/lsXXR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI=3.14159;

vec3 shd(vec2 uv){
    float speedmod=0.5;
    float speed=(sin(time)/1000.+3.)*speedmod;
    
    float scol = abs(uv.y-sin(uv.x*5.)/4.);
    
    float t = scol*(sin(uv.x+time*speed/5.)*100.)*abs(uv.y);
    
    vec3 color = vec3(sin(t));
    
    float maxstripes=10.;
    
    
    float stripes=mod(time*speed+uv.x,maxstripes*2.)-maxstripes;
    stripes = abs(stripes);
        
    vec3 ncolor;
    
    ncolor.r=-color.r;
    ncolor.g=color.g*sin(uv.x);
    ncolor.b=-ncolor.g;
    
    float sm=1.;
    
    float ml = smoothstep(PI*stripes+sm,PI*stripes-sm,abs(t));
    
    color = mix(color,ncolor,ml);
    //color = ncolor;
    
    float saturation=sin(uv.x*sin(uv.x*10.+time*speed+sin(uv.y*10.+sin(uv.x*15.))/4.)*10.+time*speed)+2.;
    
    color=color*saturation;
    
    return color;
}

float heightmap(vec2 uv){
    vec3 c = shd(uv);
    //return (c.r+c.g+c.b)/2.;
    //return min(c.r,min(c.g,c.b));
    return c.r*0.2126 + c.g*0.7152 + c.b*0.0722; //greyscale
}

vec3 normalmap(vec2 uv, float spread){
    vec3 color = vec3(0.);
    
    float depth=0.;
    
    float p[4];
    p[0] = heightmap(uv+vec2(-spread,-spread));
    p[1] = heightmap(uv+vec2( spread,-spread));
    p[2] = heightmap(uv+vec2(-spread, spread));
    p[3] = heightmap(uv+vec2( spread, spread));
    
    float xsl = (p[1]+p[3])/2.-(p[0]+p[2])/2.;
    float ysl = (p[0]+p[1])/2.-(p[2]+p[3])/2.;
    
    float saturate=0.5/length(vec3(xsl,ysl,depth));
    
    vec3 nor = normalize(vec3(xsl,ysl,spread))/2.;
    
    color.r=0.5+nor.x;
    color.g=0.5+nor.y;
    color.b=0.5+nor.z;
    
    return vec3(color);
    
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy) / resolution.y;
    
    
    //uv.y+=1.;
    uv.y*=0.8;
    //uv.x*=1.5;
    uv.y*=(uv.y*uv.y)+0.9;
        

    vec3 lvec = vec3(sin(time)/10.,cos(time*1.15)/10.,1.);
    lvec = normalize(lvec);
    
    
    
    //color=color*(floor(mod(uv.x,0.2+sin(time)+1.)*10.)*2.-1.);
    
    vec3 nrm = normalmap(uv,0.001);
    
    float ambient = clamp(dot(lvec,nrm),0.,1.);
    //ambient=pow(ambient/2.+0.5,5.);
    ambient=pow(ambient,2.);
    
    vec3 color = shd(uv);
    color=color*ambient;
    //color = vec3(ambient);
    
    glFragColor = vec4(color,1.0);
}
