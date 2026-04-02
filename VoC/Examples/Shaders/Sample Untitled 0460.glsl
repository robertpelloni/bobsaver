#version 420

// original https://www.shadertoy.com/view/wdVGR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdSphere(vec3 pos,float len){
    return length(sin(pos)) - len;

}

float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p);
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float castRay(vec3 ro,vec3 rd){

    float t = 0.0;
    
    for(int i = 0 ;i < 500 ;i++){
        
        vec3 p = ro + rd * t;
        
        
        float r = sdSphere(p - vec3(0.0,time, 0.0) ,0.5);
        
      //  float r = sdBox(p - vec3(0.0,time, 0.0),vec3(0.8));
        
      //  float r = sdTorus(p - vec3(sin(time*0.5),0.0,0.0),vec2(0.5,0.5));
        
      //  r = r <= r2 ? r: r2;
        
        
        if(abs(r)<0.001*t)
        { 
           return t;
        }
         t += r;
        
        
    }
    return -1.0;
}

vec3 render(vec3 ro,vec3 rd){
    
    float t = castRay(ro,rd);

    if(t > 0.0 && t < 30.0){
        
        vec3 pos = ro + rd *t;

        vec3 lightPos = vec3(sin(time)*10.0,cos(time)*10.0,cos(time)*10.0+5.0);

        vec3 lightDir = normalize(lightPos - pos );

        float f = clamp (dot(pos,lightDir) , 0.0,3.0);
        
        vec3 srcCol = vec3(0.3,0.4,0.8);

        vec3 l = srcCol * f;
        

        return vec3(l);
    }
    
    return vec3(0.5);
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr),cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    
    float time = 15.0 + time*1.5;
    
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    //float pixel = 1.0/resolution.y;
    
    // camera    
    vec3 ta = vec3(0.5, -0.4, -0.5);
    vec3 ro = ta + vec3(sin(time)*2.0,sin(time)*3.0-2.0,cos(time)*2.9-10.0);
    
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta,0.0 );

    vec3 rd = ca * normalize( vec3(uv,2.0) );
    
    glFragColor = vec4(render(ro,rd),1.0);
    
    
}
