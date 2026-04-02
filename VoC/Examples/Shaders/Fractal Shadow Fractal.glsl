#version 420

// original https://www.shadertoy.com/view/4djBDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*by musk License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. */

float dfpart(vec3 pos, float rep,float interp){
    vec3 rep3 = vec3(rep,rep,rep);
    pos = mod(pos+rep3,rep3*2.0)-rep3;
    float d=rep;
    /*d = min(d,length(pos.xy));
    d = min(d,length(pos.yz));
    d = min(d,length(pos.zx));
    return rep*.5-d;*/
    return rep*(1.15+interp*.27)-length(pos);
}

float hash(vec2 v){
    return fract(fract(sin(dot(v,vec2(51.651244215,2.141625)*7.12311)*412.1234)*517.5126751)*711.123173173+time);
}

float df(vec3 pos){
    float interp = cos(time*0.1);
    interp = interp*interp*interp;
    float d = 0.0,e=16.0;
    for (float i=.0; i<4.; i++){
        d = max(d,dfpart(pos,e,interp));
        if (d>e*.125) break;
        e*=.2712;
    }
    return d;
}

vec3 nf(vec3 p){
    vec2 e = vec2(.0,.001);
    float c = df(p);
    return normalize(vec3(df(p-e.yxx)-df(p+e.yxx),df(p-e.xyx)-df(p+e.xyx),df(p-e.xxy)-df(p+e.xxy)));
}

void rot(inout vec2 v,float a){
    float c=cos(a),s=sin(a);
    v*=mat2(c,s,-s,c);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.yy - vec2(.85,.5);
    float t = time + hash(uv)/60.0;
    vec3 p = sin(vec3(t*.172, t*.271, t*.314)*2.0)+t;
    float luv = length(uv);
    vec3 dir = normalize(vec3(uv.xy,1.0-luv*luv*.6));
    
    vec3 lightp = vec3(t) + normalize(sin(p*.1))*5.0 + dir*15.0;
    
    rot(dir.xy,t*.1);
    rot(dir.yz,t*.05);
    rot(dir.zx,t*.025);
    p+=dir*hash(uv)*.1;
    float it;
    
    for(float i=0.0; i<100.0; i+=1.){
        float d = df(p);
        p+=d*dir;
        it = i;
        if (d<.01){
            break;
        }
    }
    
    vec3 d2 = normalize(lightp-p);
    float td = .01;
    vec3 p2 = p+d2*(td+td*hash(uv));
    float occlusion = 1.0;
    float mtd = distance(lightp,p);
    
    for(float i=0.0; i<100.0;i++){
        float d = df(p2);
        p2 += d*d2;
        td += d;
        if (td>mtd || occlusion<.0) break;
        occlusion = min(occlusion,d/(td*.05));
    }
    occlusion=max(occlusion,0.0);
    
    float diffuse = dot(nf(p),-d2)*.5+.5;
    vec3 lcolor = vec3(.9,.3,.1)*.5;
    vec3 color= diffuse*lcolor/(1.0+mtd*mtd*.0005)*4.0*occlusion+lcolor/(1.0+mtd*mtd*.0005)*.5;
    color += (vec3(1)-lcolor)*(td*.001+occlusion+it/200.0)*.5;
    color *= (1.0-length(uv));
    color = vec3(1.8)*color/(vec3(1)+color);
    color = pow(color,vec3(0.8));

    //color = nf(p)*.5+.5;
    glFragColor = vec4(color,1.0);
}
