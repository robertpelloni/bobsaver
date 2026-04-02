#version 420

// original https://www.shadertoy.com/view/7sjSRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 palette(float d){
    return mix(vec3(0.0,3.02,1.24),vec3(1.,0.01,3.2),d);
}

vec2 rotate(vec2 p,float a){
    float c = cos(a);
    float s = sin(a);
    return p*mat2(c,s,-s,c);
}

float map(vec3 p){
    for( int i = 0; i<28; ++i){
        float t = time*0.2;
        p.xz =rotate(p.xz,t);
        p.xy =rotate(p.xy,t*3.0);
        p.xz = abs(p.xz);
        p.xz-=.16;
    }
    return dot(sign(p),p)/6.;
}

vec4 rm (vec3 ro, vec3 rd){
    float t = 1.;
    vec3 col = vec3(0.001);
    float d;
    for(float i =0.; i<36.; i++){
        vec3 p = ro + rd*t;
        d = map(p)*.88;
        if(d<0.1){
            break;
        }
        if(d>22.){
            break;
        }
        //col+=vec3(3.6,3.8,3.8)/(400.*(d));
        col+=palette(length(p)*.1)/(222.*(d));
        t+=d;
    }
    return vec4(col,1./(d*20.));
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-(resolution.xy/2.))/resolution.x;
    vec3 ro = vec3(55.,55.,-13.);
    ro.xz = rotate(ro.xz,time);
    vec3 cf = normalize(-ro);
    vec3 cs = normalize(cross(cf,vec3(7,3.,7.)));
    vec3 cu = normalize(cross(cf,cs));
    
    vec3 uuv = ro+cf*3. + uv.x*cs + uv.y*cu;
    
    vec3 rd = normalize(uuv-ro);
    
    vec4 col = rm(ro,rd);
    
    
    glFragColor = col;
}

/** SHADERDATA
{
    "title": "fractal pyramid",
    "description": "",
    "model": "car"
}
*/
