#version 420

// original https://www.shadertoy.com/view/tlXGR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphere(vec3 p, float r){
    p = mod(p,3.)-3.*.5;
    return length(p)-r;
}
float map (vec3 p){
    return sphere(p,.5);
}
float diffuse(vec3 n, vec3 l){
    return dot(n,normalize(l)) * .5 + .5;
}
vec3 get_normal(vec3 p){
    vec2 eps = vec2(0.001,0.);
    return normalize(vec3(  map(p+eps.xyy) - map(p-eps.xyy),
                            map(p+eps.yxy) - map(p-eps.yxy),
                            map(p+eps.yyx) - map(p-eps.yyx)));
}
void main(void)
{
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    uv-=.5;    
    uv.x*=resolution.x/resolution.y;
    uv.x = abs(uv.x);
    uv.y = abs(uv.y);
    vec4 col = vec4(.2);

    vec3 ro = vec3(0.,0.,-3.);
    vec3 rd = normalize(vec3(uv,1.));
    vec3 p = ro;
    
    p.x = sin(time * uv.y);    
    p.y = sin(time * -uv.x);

    bool hit = false;
    float shading = 0.;
    float dist = 100.;
    for(float i=0.; i<dist; i++){
        float d = map(p);
        if(d<.05){
            hit = true;
            shading = i/dist;
            break;
        }
        p += d * rd * 0.8;
    }
    if(hit){
        vec3 n = get_normal(p);
        vec3 l = vec3(.5,sin(time),-1.);
        col.rgb = mix(vec3(.1,0.,.2), vec3(.8,0.,.3), vec3(diffuse(n,l)));
    } 
    else col.rgb = vec3(0.);
    

    float t = length(ro-p);
    
    col.rgb = mix(col.rgb, vec3(31.0,2,30)/255.0, 1.-exp(-0.002*t*t));    
    
    
    
    glFragColor=col;
}
